import SwiftUI
import UserNotifications
import SwiftData

struct NotificationSettingsView: View {
    @Bindable var settings: AppSettings
    @Query private var allOverrides: [EatingWindowOverride]
    @Environment(\.modelContext) private var modelContext
    
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable notifications", isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { oldValue, newValue in
                        if newValue {
                            Task {
                                await checkAndRequestPermission()
                            }
                        } else {
                            NotificationService.shared.cancelAllNotifications()
                        }
                        rescheduleNotifications()
                    }
            }
            
            if settings.notificationsEnabled {
                Section("Window Start") {
                    HStack {
                        Text("Notify before start")
                        Spacer()
                        Stepper(
                            "\(settings.notifyBeforeWindowStartMinutes) min",
                            value: $settings.notifyBeforeWindowStartMinutes,
                            in: 1...120,
                            step: 5
                        )
                        .onChange(of: settings.notifyBeforeWindowStartMinutes) { oldValue, newValue in
                            rescheduleNotifications()
                        }
                    }
                }
                
                Section("Window End") {
                    HStack {
                        Text("Notify before end")
                        Spacer()
                        Stepper(
                            "\(settings.notifyBeforeWindowEndMinutes) min",
                            value: $settings.notifyBeforeWindowEndMinutes,
                            in: 1...120,
                            step: 5
                        )
                        .onChange(of: settings.notifyBeforeWindowEndMinutes) { oldValue, newValue in
                            rescheduleNotifications()
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: authStatusIcon)
                                .foregroundStyle(authStatusColor)
                            Text(authStatusText)
                        }
                        
                        if authStatus == .denied {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } else if authStatus == .notDetermined {
                            Button("Request Permission") {
                                Task {
                                    await requestPermission()
                                }
                            }
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            authStatus = await NotificationService.shared.checkAuthorizationStatus()
        }
    }
    
    // MARK: - Permission Handling
    
    private func checkAndRequestPermission() async {
        authStatus = await NotificationService.shared.checkAuthorizationStatus()
        if authStatus == .notDetermined {
            await requestPermission()
        }
    }
    
    private func requestPermission() async {
        let granted = await NotificationService.shared.requestAuthorization()
        authStatus = await NotificationService.shared.checkAuthorizationStatus()
        if !granted {
            settings.notificationsEnabled = false
        }
    }
    
    // MARK: - Notification Scheduling
    
    private func rescheduleNotifications() {
        guard settings.notificationsEnabled,
              let schedule = settings.selectedSchedule else {
            NotificationService.shared.cancelAllNotifications()
            return
        }
        
        NotificationService.shared.scheduleEatingWindowNotifications(
            schedule: schedule,
            overrides: allOverrides,
            settings: settings
        )
    }
    
    // MARK: - UI Helpers
    
    private var authStatusIcon: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    private var authStatusColor: Color {
        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var authStatusText: String {
        switch authStatus {
        case .authorized:
            return "Notifications are enabled"
        case .denied:
            return "Notifications are disabled in system settings"
        case .notDetermined:
            return "Permission not requested yet"
        case .provisional:
            return "Provisional authorization granted"
        case .ephemeral:
            return "Ephemeral authorization granted"
        @unknown default:
            return "Unknown authorization status"
        }
    }
}
