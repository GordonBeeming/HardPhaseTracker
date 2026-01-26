import Foundation
import UserNotifications
import SwiftData

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Scheduling
    
    func scheduleEatingWindowNotifications(
        schedule: EatingWindowSchedule,
        overrides: [EatingWindowOverride],
        settings: AppSettings,
        calendar: Calendar = .current
    ) {
        // Cancel all existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard settings.notificationsEnabled else { return }
        
        // Schedule for next 14 days
        let today = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: 14, to: today) else { return }
        
        for dayOffset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Check if this day has an override
            let normalizedDate = calendar.startOfDay(for: date)
            let override = overrides.first { calendar.isDate($0.date, inSameDayAs: normalizedDate) }
            
            // Determine if this is an eating day
            let isEatingDay: Bool
            if let override = override {
                isEatingDay = override.overrideTypeEnum == .eating
            } else {
                let weekday = calendar.component(.weekday, from: date)
                isEatingDay = schedule.isActive(on: weekday)
            }
            
            guard isEatingDay else { continue }
            
            // Get window times (from override or schedule)
            let startMinutes = override?.startMinutes ?? schedule.startMinutes
            let endMinutes = override?.endMinutes ?? schedule.endMinutes
            
            // Calculate notification times
            let windowStartTime = calendar.date(byAdding: .minute, value: startMinutes, to: normalizedDate)!
            let windowEndTime = calendar.date(byAdding: .minute, value: endMinutes, to: normalizedDate)!
            
            // Schedule start notification
            if let notifyStartTime = calendar.date(byAdding: .minute, value: -settings.notifyBeforeWindowStartMinutes, to: windowStartTime),
               notifyStartTime > Date() {
                scheduleNotification(
                    id: "window-start-\(normalizedDate.timeIntervalSince1970)",
                    title: "Eating Window Opening Soon",
                    body: "Your eating window opens in \(settings.notifyBeforeWindowStartMinutes) minutes",
                    date: notifyStartTime
                )
            }
            
            // Schedule end notification
            if let notifyEndTime = calendar.date(byAdding: .minute, value: -settings.notifyBeforeWindowEndMinutes, to: windowEndTime),
               notifyEndTime > Date() {
                scheduleNotification(
                    id: "window-end-\(normalizedDate.timeIntervalSince1970)",
                    title: "Eating Window Closing Soon",
                    body: "Your eating window closes in \(settings.notifyBeforeWindowEndMinutes) minutes",
                    date: notifyEndTime
                )
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Private Helpers
    
    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
