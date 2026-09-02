import SwiftUI
import UIKit
import WidgetKit

enum WidgetChrome {
    static let weights = Color(red: 0x6E / 255, green: 0xA8 / 255, blue: 0xFE / 255)
    static let running = Color(red: 0xFE / 255, green: 0xE4 / 255, blue: 0x40 / 255)
    static let both = Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x7A / 255)

    static func accent(from hex: String) -> Color {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            return Color(red: 0.98, green: 0.42, blue: 0.18)
        }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    static func stressColor(for score: Double) -> Color {
        switch score {
        case ..<30.5: return Color(red: 0.30, green: 0.72, blue: 0.48)
        case ..<55.5: return Color(red: 0.25, green: 0.55, blue: 0.90)
        case ..<75.5: return Color(red: 0.95, green: 0.58, blue: 0.18)
        default: return Color(red: 0.90, green: 0.25, blue: 0.28)
        }
    }

    static func stressLabel(for score: Double) -> String {
        switch score {
        case ..<30.5: return "Recovery"
        case ..<55.5: return "Productive"
        case ..<75.5: return "High"
        default: return "Very high"
        }
    }

    static func color(for kind: WidgetYearActivityKind, inYear: Bool) -> Color {
        switch kind {
        case .weights: return weights
        case .running: return running
        case .both: return both
        case .none: return inYear ? Color.primary.opacity(0.12) : .clear
        }
    }
}

struct WorkoutYearWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WorkoutWidgetEntry

    var body: some View {
        let snap = entry.snapshot
        Group {
            switch family {
            case .systemSmall:
                yearStat(snap)
            case .systemLarge:
                yearLarge(snap)
            default:
                yearMedium(snap)
            }
        }
        .widgetChrome(padding: family == .systemMedium ? 6 : 14)
    }

    private func yearStat(_ snap: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: String(snap.year))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(snap.activityDayCount)")
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
            Text(snap.activityDayCount == 1 ? "workout day" : "workout days")
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 0)
            Text("Day \(snap.dayOfYear)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func yearMedium(_ snap: WidgetSnapshot) -> some View {
        if family == .systemMedium {
            yearMediumDashboard(snap)
        } else {
            yearMediumLegacy(snap)
        }
    }

    /// Home-style compact header: day-of-year on the left, counted legend on the right. No year title.
    private func yearMediumDashboard(_ snap: WidgetSnapshot) -> some View {
        let daysInYear = Self.daysInYear(snap.year)
        let bothCount = Self.bothDayCount(snap)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Text("\(snap.dayOfYear) / \(daysInYear) days")
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 4)
                HStack(spacing: 8) {
                    legend("Weights (\(snap.liftSessionCount))", color: WidgetChrome.weights)
                    legend("Running (\(snap.runDayStarts.count))", color: WidgetChrome.running)
                    legend("Both (\(bothCount))", color: WidgetChrome.both)
                }
            }
            WidgetYearGridView(snapshot: snap, dense: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Shared by the large family — keep the year title and original legend.
    private func yearMediumLegacy(_ snap: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: String(snap.year))
                    .font(.headline)
                Spacer()
                Text("\(snap.activityDayCount) days · \(snap.dayOfYear)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            WidgetYearGridView(snapshot: snap, dense: false)
            HStack(spacing: 10) {
                legend("Weights", color: WidgetChrome.weights)
                legend("Running", color: WidgetChrome.running)
                legend("Both", color: WidgetChrome.both)
            }
        }
    }

    private static func daysInYear(_ year: Int) -> Int {
        let calendar = Calendar.current
        let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        return calendar.range(of: .day, in: .year, for: jan1)?.count ?? 365
    }

    private static func bothDayCount(_ snap: WidgetSnapshot) -> Int {
        let lifts = Set(snap.liftDayStarts)
        let runs = Set(snap.runDayStarts)
        return lifts.intersection(runs).count
    }

    private func yearLarge(_ snap: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            yearMedium(snap)
            HStack(alignment: .top, spacing: 16) {
                stressBlock(snap)
                VStack(alignment: .leading, spacing: 4) {
                    Text("This week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(snap.recentActivityDays)")
                        .font(.title2.monospacedDigit().weight(.bold))
                    Text(snap.recentActivityDays == 1 ? "active day" : "active days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func stressBlock(_ snap: WidgetSnapshot) -> some View {
        let color = WidgetChrome.stressColor(for: snap.todayStress)
        return VStack(alignment: .leading, spacing: 4) {
            Text("Today’s stress")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(snap.todayStress.rounded()))")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(color)
                Text(WidgetChrome.stressLabel(for: snap.todayStress))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            StressSparkline(values: snap.trendTotals, color: color)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: family == .systemMedium ? 7 : 6, height: family == .systemMedium ? 7 : 6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

struct WorkoutStressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WorkoutWidgetEntry

    var body: some View {
        let snap = entry.snapshot
        let color = WidgetChrome.stressColor(for: snap.todayStress)
        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(snap.todayStress.rounded()))")
                        .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(color)
                    Text(WidgetChrome.stressLabel(for: snap.todayStress))
                        .font(.subheadline.weight(.medium))
                    Spacer(minLength: 0)
                    StressSparkline(values: snap.trendTotals, color: color)
                        .frame(height: 22)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Today’s stress")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(snap.todayStress.rounded()))")
                            .font(.title.monospacedDigit().weight(.bold))
                            .foregroundStyle(color)
                    }
                    Text(WidgetChrome.stressLabel(for: snap.todayStress))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.10))
                            Capsule()
                                .fill(color)
                                .frame(width: max(8, geo.size.width * min(max(snap.todayStress / 100, 0), 1)))
                        }
                    }
                    .frame(height: 7)

                    StressSparkline(values: snap.trendTotals, color: WidgetChrome.accent(from: snap.accentHex))
                        .frame(height: 44)

                    HStack {
                        split("Lift", snap.todayLift)
                        split("Run", snap.todayRun)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .widgetChrome()
    }

    private func split(_ title: String, _ score: Double) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Text("\(Int(score.rounded()))")
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkoutNextWidgetView: View {
    let entry: WorkoutWidgetEntry

    var body: some View {
        let snap = entry.snapshot
        VStack(alignment: .leading, spacing: 8) {
            if let next = snap.nextDayName {
                labeled("Next", title: next, subtitle: snap.nextProgramName)
            } else {
                labeled("Next", title: "No program", subtitle: "Open Workout to set one")
            }
            Spacer(minLength: 0)
            if let last = snap.lastWorkoutTitle {
                labeled("Last", title: last, subtitle: relativeDate(snap.lastWorkoutDate))
            } else {
                labeled("Last", title: "—", subtitle: "No sessions yet")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetChrome()
    }

    private func labeled(_ eyebrow: String, title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(eyebrow)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .lineLimit(1)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func relativeDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
        if days > 0 && days < 14 { return "\(days)d ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct WidgetYearGridView: View {
    let snapshot: WidgetSnapshot
    var showMonths: Bool = true
    var dense: Bool = false

    private static let monthLetters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

    var body: some View {
        let cells = WidgetYearGridBuilder.cells(
            year: snapshot.year,
            liftDayStarts: snapshot.liftDayStarts,
            runDayStarts: snapshot.runDayStarts
        )
        GeometryReader { geo in
            let spacing: CGFloat = dense ? 0.55 : 1.4
            let columns = 53
            let monthH: CGFloat = showMonths ? 9 : 0
            let monthGap: CGFloat = showMonths ? (dense ? 2 : 3) : 0
            let availableH = max(geo.size.height - monthH - monthGap, 1)
            let rawW = (geo.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            let rawH = (availableH - 6 * spacing) / 7
            let cellCap: CGFloat = dense ? 10 : 5.5
            let cell = min(max(min(rawW, rawH), 2.4), cellCap)

            VStack(alignment: .leading, spacing: monthGap == 0 ? 0 : monthGap) {
                if showMonths {
                    monthLabels(cells: cells, cell: cell, spacing: spacing)
                }
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { row in
                                let index = col * 7 + row
                                if index < cells.count {
                                    let item = cells[index]
                                    Circle()
                                        .fill(WidgetChrome.color(for: item.kind, inYear: item.inYear))
                                        .frame(width: cell, height: cell)
                                        .overlay {
                                            if item.inYear && Calendar.current.isDateInToday(item.date) {
                                                Circle().strokeBorder(Color.primary.opacity(0.45), lineWidth: 0.8)
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: dense ? .infinity : nil)
        .frame(height: dense ? nil : (showMonths ? 58 : 46))
        .accessibilityLabel("Year activity grid")
    }

    private func monthLabels(cells: [WidgetYearCell], cell: CGFloat, spacing: CGFloat) -> some View {
        let labels = monthStarts(cells)
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
        .frame(height: 9)
    }

    private func monthStarts(_ cells: [WidgetYearCell]) -> [(offset: Int, column: Int, label: String)] {
        var seen: Set<Int> = []
        var result: [(offset: Int, column: Int, label: String)] = []
        let cal = Calendar.current
        for (index, cell) in cells.enumerated() where cell.inYear {
            let month = cal.component(.month, from: cell.date)
            if seen.insert(month).inserted {
                result.append((result.count, index / 7, Self.monthLetters[month - 1]))
            }
        }
        return result
    }
}

struct StressSparkline: View {
    let values: [Double]
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            ZStack {
                Path { path in
                    guard let first = pts.first else { return }
                    path.move(to: first)
                    for point in pts.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if let last = pts.last {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .position(last)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let count = values.count
        return values.enumerated().map { index, value in
            let x = count == 1 ? size.width / 2 : size.width * CGFloat(index) / CGFloat(count - 1)
            let y = size.height * (1 - CGFloat(min(max(value / 100, 0), 1)))
            return CGPoint(x: x, y: y)
        }
    }
}

private struct WidgetChromeModifier: ViewModifier {
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) {
                Color(uiColor: .secondarySystemBackground)
            }
    }
}

private extension View {
    func widgetChrome(padding: CGFloat = 14) -> some View {
        modifier(WidgetChromeModifier(padding: padding))
    }
}

#Preview("Year medium", as: .systemMedium) {
    WorkoutYearWidget()
} timeline: {
    WorkoutWidgetEntry(date: .now, snapshot: .preview)
}

#Preview("Stress medium", as: .systemMedium) {
    WorkoutStressWidget()
} timeline: {
    WorkoutWidgetEntry(date: .now, snapshot: .preview)
}
