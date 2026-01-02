import SwiftUI
import Foundation

struct MealCalendarView: View {
    @Binding var selectedDate: Date

    @State private var month: Date = .now
    @State private var isShowingJumpPicker = false
    @State private var jumpDate: Date = .now

    var body: some View {
        VStack(spacing: 10) {
            header
            grid
        }
        .onAppear {
            month = selectedDate
        }
        .onChange(of: selectedDate) { _, newValue in
            month = newValue
        }
        .sheet(isPresented: $isShowingJumpPicker) {
            NavigationStack {
                DatePicker("", selection: $jumpDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .navigationTitle("Jump to month")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isShowingJumpPicker = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                selectedDate = jumpDate
                                isShowingJumpPicker = false
                            }
                        }
                    }
                    .padding()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthTitle(month))
                .font(.headline)

            Spacer()

            Button {
                let today = Date()
                selectedDate = today
                month = today
            } label: {
                Text("Today")
                    .font(.subheadline)
            }

            Button {
                jumpDate = selectedDate
                isShowingJumpPicker = true
            } label: {
                Image(systemName: "calendar")
            }

            Button {
                month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.top, 8)
    }

    private var grid: some View {
        let cal = Calendar.current
        let days = daysInMonthGrid(for: month, calendar: cal)

        return VStack(spacing: 8) {
            HStack {
                ForEach(Array(weekdaySymbols(calendar: cal).enumerated()), id: \.offset) { _, s in
                    Text(s)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    dayCell(day, calendar: cal)
                }
            }
        }
    }

    private func dayCell(_ date: Date, calendar: Calendar) -> some View {
        let isInMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout)
                    .frame(maxWidth: .infinity)

            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isInMonth ? .primary : .secondary)
        .opacity(isInMonth ? 1 : 0.35)
    }

    private func daysInMonthGrid(for month: Date, calendar: Calendar) -> [Date] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<2

        let firstWeekdayIndex = calendar.component(.weekday, from: startOfMonth) - calendar.firstWeekday
        let leading = (firstWeekdayIndex + 7) % 7

        var days: [Date] = []
        days.reserveCapacity(42)

        for i in 0..<leading {
            if let d = calendar.date(byAdding: .day, value: -(leading - i), to: startOfMonth) {
                days.append(d)
            }
        }

        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(d)
            }
        }

        while days.count % 7 != 0 {
            if let last = days.last, let next = calendar.date(byAdding: .day, value: 1, to: last) {
                days.append(next)
            } else {
                break
            }
        }

        return days
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let shift = (calendar.firstWeekday - 1) % 7
        return Array(symbols[shift...] + symbols[..<shift])
    }

}
