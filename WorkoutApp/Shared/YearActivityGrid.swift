import SwiftUI
import SwiftData

struct YearDayCell: Identifiable {
    let id: Date
    let date: Date
    let inYear: Bool
    let volume: Double
    let workoutCount: Int
}

enum YearGridBuilder {
    static func cells(year: Int, sessions: [WorkoutSession], calendar: Calendar = .current) -> [YearDayCell] {
        var cal = calendar
        cal.firstWeekday = 1

        var volumeByDay: [Date: Double] = [:]
        var countByDay: [Date: Int] = [:]
        for session in sessions where session.endDate != nil {
            let day = cal.startOfDay(for: session.startDate)
            let vol = session.sets.reduce(0.0) { $0 + $1.volume }
            volumeByDay[day, default: 0] += vol
            countByDay[day, default: 0] += 1
        }

        guard let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else { return [] }
        let weekday = cal.component(.weekday, from: jan1)
        let offset = weekday - cal.firstWeekday
        guard let start = cal.date(byAdding: .day, value: -offset, to: jan1) else { return [] }

        var result: [YearDayCell] = []
        result.reserveCapacity(53 * 7)
        for i in 0..<(53 * 7) {
            guard let date = cal.date(byAdding: .day, value: i, to: start) else { continue }
            let day = cal.startOfDay(for: date)
            let inYear = cal.component(.year, from: date) == year
            result.append(
                YearDayCell(
                    id: date,
                    date: date,
                    inYear: inYear,
                    volume: inYear ? (volumeByDay[day] ?? 0) : 0,
                    workoutCount: inYear ? (countByDay[day] ?? 0) : 0
                )
            )
        }
        return result
    }
}

struct YearActivityGrid: View {
    let sessions: [WorkoutSession]
    var year: Int = Calendar.current.component(.year, from: Date())
    var onSelect: ((Date) -> Void)? = nil

    @Environment(\.calendar) private var calendar

    private var cells: [YearDayCell] {
        YearGridBuilder.cells(year: year, sessions: sessions, calendar: calendar)
    }

    private var maxVolume: Double {
        max(cells.map(\.volume).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(year)")
                    .font(.headline)
                Spacer()
                Text("Activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let spacing: CGFloat = 2
                let columns = 53
                let cell = max(3.5, (geo.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns))
                let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

                HStack(alignment: .top, spacing: 4) {
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { row in
                            Text(weekdays[row])
                                .font(.system(size: 7, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 8, height: cell)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        monthLabels(cell: cell, spacing: spacing)
                        HStack(alignment: .top, spacing: spacing) {
                            ForEach(0..<columns, id: \.self) { col in
                                VStack(spacing: spacing) {
                                    ForEach(0..<7, id: \.self) { row in
                                        let index = col * 7 + row
                                        if index < cells.count {
                                            dayDot(cells[index], size: cell)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 118)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Year activity grid")
            .onTapGesture {
                onSelect?(Date())
            }
        }
        .padding(14)
        .opaqueCard()
    }

    private func monthLabels(cell: CGFloat, spacing: CGFloat) -> some View {
        let labels = monthStarts()
        return HStack(spacing: 0) {
            ForEach(labels, id: \.offset) { item in
                Text(item.label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: cell + spacing, alignment: .leading)
                if item.offset < labels.count - 1 {
                    let gap = labels[item.offset + 1].column - item.column - 1
                    Spacer().frame(width: max(0, CGFloat(gap) * (cell + spacing)))
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 10)
    }

    private func monthStarts() -> [(offset: Int, column: Int, label: String)] {
        var seen: Set<Int> = []
        var result: [(offset: Int, column: Int, label: String)] = []
        for (index, cell) in cells.enumerated() where cell.inYear {
            let month = calendar.component(.month, from: cell.date)
            if seen.insert(month).inserted {
                let col = index / 7
                result.append((result.count, col, Formatters.month.string(from: cell.date)))
            }
        }
        return result
    }

    @ViewBuilder
    private func dayDot(_ cell: YearDayCell, size: CGFloat) -> some View {
        let filled = cell.inYear && cell.workoutCount > 0
        let intensity = filled ? 0.28 + 0.72 * min(cell.volume / maxVolume, 1) : 0
        Circle()
            .fill(filled ? Color.accentColor.opacity(intensity) : (cell.inYear ? Theme.mutedFill : Color.clear))
            .frame(width: size, height: size)
            .overlay {
                if cell.inYear && calendar.isDateInToday(cell.date) {
                    Circle().strokeBorder(Color.primary.opacity(0.45), lineWidth: 1)
                }
            }
    }
}
