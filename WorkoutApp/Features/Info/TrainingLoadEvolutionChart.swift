import SwiftUI
import Charts

private enum TrainingLoadChartMode: String, CaseIterable, Identifiable {
    case absolute, normalized

    var id: String { rawValue }

    var title: String {
        switch self {
        case .absolute: return "Absolute"
        case .normalized: return "Normalized"
        }
    }
}

private enum AbsoluteMetric: String, CaseIterable, Identifiable {
    case tonnage, sets, reps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tonnage: return "Tonnage"
        case .sets: return "Sets"
        case .reps: return "Reps"
        }
    }
}

private struct NormalizedLoadPoint: Identifiable {
    let id: String
    let weekStart: Date
    let metric: String
    let percent: Double
}

struct TrainingLoadEvolutionChart: View {
    let sets: [SetLog]
    let accent: Color

    @Environment(AppTheme.self) private var theme
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @State private var mode: TrainingLoadChartMode = .absolute
    @State private var absoluteMetric: AbsoluteMetric = .tonnage

    private var unit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var weeklyData: [WeeklyTrainingLoad] {
        StressCalculator.weeklyTrainingLoad(from: sets, weeks: 12)
    }

    private var maxTonnage: Double {
        max(weeklyData.map(\.tonnageKg).max() ?? 0, 1)
    }

    private var maxSets: Double {
        max(Double(weeklyData.map(\.setCount).max() ?? 0), 1)
    }

    private var maxReps: Double {
        max(Double(weeklyData.map(\.repCount).max() ?? 0), 1)
    }

    private var normalizedPoints: [NormalizedLoadPoint] {
        weeklyData.flatMap { week in
            [
                NormalizedLoadPoint(
                    id: "\(week.weekStart.timeIntervalSince1970)-tonnage",
                    weekStart: week.weekStart,
                    metric: "Tonnage",
                    percent: week.tonnageKg / maxTonnage * 100
                ),
                NormalizedLoadPoint(
                    id: "\(week.weekStart.timeIntervalSince1970)-sets",
                    weekStart: week.weekStart,
                    metric: "Sets",
                    percent: Double(week.setCount) / maxSets * 100
                ),
                NormalizedLoadPoint(
                    id: "\(week.weekStart.timeIntervalSince1970)-reps",
                    weekStart: week.weekStart,
                    metric: "Reps",
                    percent: Double(week.repCount) / maxReps * 100
                )
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training load evolution")
                .font(.headline)
            Text("Weekly totals over the last 12 weeks (Monday start).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Mode", selection: $mode) {
                ForEach(TrainingLoadChartMode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            if mode == .absolute {
                Picker("Metric", selection: $absoluteMetric) {
                    ForEach(AbsoluteMetric.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                absoluteChart
            } else {
                normalizedChart
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private var absoluteChart: some View {
        Chart(weeklyData) { week in
            LineMark(
                x: .value("Week", week.weekStart),
                y: .value(absoluteMetric.title, absoluteValue(for: week))
            )
            .foregroundStyle(accent)
            PointMark(
                x: .value("Week", week.weekStart),
                y: .value(absoluteMetric.title, absoluteValue(for: week))
            )
            .foregroundStyle(accent)
        }
        .frame(height: 220)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(Formatters.dayMonth.string(from: date))
                }
            }
        }
        .chartYAxisLabel(absoluteYAxisLabel)
    }

    private var normalizedChart: some View {
        Chart(normalizedPoints) { point in
            LineMark(
                x: .value("Week", point.weekStart),
                y: .value("% of best", point.percent)
            )
            .foregroundStyle(by: .value("Metric", point.metric))
            PointMark(
                x: .value("Week", point.weekStart),
                y: .value("% of best", point.percent)
            )
            .foregroundStyle(normalizedMetricColor(point.metric))
        }
        .frame(height: 220)
        .chartForegroundStyleScale([
            "Tonnage": .orange,
            "Sets": .blue,
            "Reps": .green
        ])
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(Formatters.dayMonth.string(from: date))
                }
            }
        }
        .chartYAxisLabel("% of personal best")
    }

    private func normalizedMetricColor(_ metric: String) -> Color {
        switch metric {
        case "Tonnage": return .orange
        case "Sets": return .blue
        case "Reps": return .green
        default: return accent
        }
    }

    private func absoluteValue(for week: WeeklyTrainingLoad) -> Double {
        switch absoluteMetric {
        case .tonnage: return unit.fromKg(week.tonnageKg)
        case .sets: return Double(week.setCount)
        case .reps: return Double(week.repCount)
        }
    }

    private var absoluteYAxisLabel: String {
        switch absoluteMetric {
        case .tonnage: return unit.rawValue + "·reps"
        case .sets: return "Sets"
        case .reps: return "Reps"
        }
    }
}
