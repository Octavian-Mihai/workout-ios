import SwiftUI
import Charts

struct StressLegendView: View {
    var compact: Bool = false
    var highlightScore: Double? = nil
    @Environment(AppTheme.self) private var theme

    private let bands: [(range: String, title: String, color: Color, band: StressBand)] = [
        ("0–30", "Recovery / easy", Color(red: 0.30, green: 0.72, blue: 0.48), .recovery),
        ("31–55", "Productive", Color(red: 0.25, green: 0.55, blue: 0.90), .productive),
        ("56–75", "High — watch sleep/fatigue", Color(red: 0.95, green: 0.58, blue: 0.18), .high),
        ("76–100", "Very high — consider backing off", Color(red: 0.90, green: 0.25, blue: 0.28), .veryHigh)
    ]

    private var visibleBands: [(range: String, title: String, color: Color, band: StressBand)] {
        if let highlightScore {
            let current = StressCalculator.band(for: highlightScore)
            return bands.filter { $0.band == current }
        }
        return bands
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            if highlightScore == nil {
                Text("Stress scale")
                    .font(.subheadline.weight(.semibold))
            }
            ForEach(Array(visibleBands.enumerated()), id: \.offset) { _, band in
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(band.color)
                        .frame(width: 8, height: compact ? 22 : 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(band.range)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                        Text(band.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum StressColorPreset: String, CaseIterable, Identifiable {
    case classic
    case ocean
    case ember
    case neon
    case indigo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .ocean: return "Blue / Coral / Lime"
        case .ember: return "Red / Cyan / Gold"
        case .neon: return "Magenta / Green / Amber"
        case .indigo: return "Indigo / Orange / Mint"
        }
    }

    /// Lift / cardio / total — three hues that stay distinct within each preset.
    var lift: Color {
        switch self {
        case .classic: return Color(red: 0.96, green: 0.46, blue: 0.16)
        case .ocean: return Color(red: 0.18, green: 0.48, blue: 0.92)
        case .ember: return Color(red: 0.92, green: 0.22, blue: 0.24)
        case .neon: return Color(red: 0.90, green: 0.18, blue: 0.62)
        case .indigo: return Color(red: 0.38, green: 0.32, blue: 0.90)
        }
    }

    var cardio: Color {
        switch self {
        case .classic: return Color(red: 0.10, green: 0.72, blue: 0.70)
        case .ocean: return Color(red: 0.96, green: 0.42, blue: 0.38)
        case .ember: return Color(red: 0.05, green: 0.72, blue: 0.82)
        case .neon: return Color(red: 0.18, green: 0.72, blue: 0.32)
        case .indigo: return Color(red: 0.96, green: 0.50, blue: 0.18)
        }
    }

    var total: Color {
        switch self {
        case .classic: return Color(red: 0.58, green: 0.34, blue: 0.94)
        case .ocean: return Color(red: 0.52, green: 0.82, blue: 0.18)
        case .ember: return Color(red: 0.90, green: 0.68, blue: 0.10)
        case .neon: return Color(red: 0.95, green: 0.62, blue: 0.12)
        case .indigo: return Color(red: 0.22, green: 0.82, blue: 0.62)
        }
    }
}

enum StressSourcePalette {
    static let presetKey = StressVisibility.colorPresetKey
    static let defaultPreset = StressColorPreset.classic

    static func preset(from raw: String) -> StressColorPreset {
        StressColorPreset(rawValue: raw) ?? defaultPreset
    }
}

struct StressColorPresetPicker: View {
    @Binding var presetRaw: String
    @Environment(AppTheme.self) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(StressColorPreset.allCases) { preset in
                Button {
                    presetRaw = preset.rawValue
                } label: {
                    HStack(spacing: 12) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(preset.lift)
                                .frame(width: 14, height: 14)
                            Circle()
                                .fill(preset.cardio)
                                .frame(width: 14, height: 14)
                            Circle()
                                .fill(preset.total)
                                .frame(width: 14, height: 14)
                        }
                        Text(preset.title)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        if StressSourcePalette.preset(from: presetRaw) == preset {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(preset.title) stress colors")
            }
        }
    }
}

struct StressMeter: View {
    let title: String
    let score: Double
    let accent: Color
    var compact: Bool = false
    var barColor: Color? = nil

    @Environment(AppTheme.self) private var theme

    private var band: StressBand { StressCalculator.band(for: score) }

    private var color: Color {
        if let barColor { return barColor }
        switch band {
        case .recovery: return Color(red: 0.30, green: 0.72, blue: 0.48)
        case .productive: return Color(red: 0.25, green: 0.55, blue: 0.90)
        case .high: return Color(red: 0.95, green: 0.58, blue: 0.18)
        case .veryHigh: return Color(red: 0.90, green: 0.25, blue: 0.28)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .tint(accent)
                Spacer()
                Text("\(Int(score.rounded()))")
                    .font((compact ? Font.title3 : Font.title2).monospacedDigit().weight(.bold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.mutedFill)
                    Capsule()
                        .fill(color)
                        .frame(width: max(8, geo.size.width * min(max(score / 100, 0), 1)))
                }
            }
            .frame(height: compact ? 6 : 8)
            if !compact {
                Text(band.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct StressTrendPoint: Identifiable {
    let date: Date
    let source: String
    let value: Double

    var id: String { "\(date.timeIntervalSince1970)-\(source)" }
}

struct TodayStressCard: View {
    let estimate: StressEstimate
    var showSplit: Bool = false
    var showRunSplit: Bool = true
    var trend: [DailyStress] = []
    let accent: Color
    var compact: Bool = false

    @Environment(AppTheme.self) private var theme
    @AppStorage(StressSourcePalette.presetKey) private var presetRaw = StressColorPreset.classic.rawValue

    private var palette: StressColorPreset {
        StressSourcePalette.preset(from: presetRaw)
    }

    private var trendSeries: [StressTrendPoint] {
        trend.flatMap { point in
            var points = [
                StressTrendPoint(date: point.date, source: "Lift", value: point.lift),
                StressTrendPoint(date: point.date, source: "Total", value: point.total)
            ]
            if showRunSplit {
                points.append(StressTrendPoint(date: point.date, source: "Cardio", value: point.run))
            }
            return points
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 12) {
            StressMeter(
                title: "Today’s stress",
                score: estimate.total,
                accent: accent,
                compact: compact,
                barColor: palette.total
            )
            if showSplit {
                HStack(spacing: 16) {
                    splitMeter(title: "Lift", score: estimate.lift, color: palette.lift)
                    if showRunSplit {
                        splitMeter(title: "Cardio", score: estimate.run, color: palette.cardio)
                    }
                }
                sourceLegend
            }
            if !compact, trend.count >= 2 {
                Chart(trendSeries) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Stress", point.value)
                    )
                    .foregroundStyle(by: .value("Source", point.source))
                    PointMark(
                        x: .value("Day", point.date),
                        y: .value("Stress", point.value)
                    )
                    .foregroundStyle(by: .value("Source", point.source))
                }
                .chartForegroundStyleScale([
                    "Lift": palette.lift,
                    "Cardio": palette.cardio,
                    "Total": palette.total
                ])
                .chartLegend(.hidden)
                .frame(height: 120)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                Text("Leftover fatigue eases over the next couple of mornings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            StressLegendView(
                compact: true,
                highlightScore: compact ? estimate.total : nil
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 12 : 16)
        .opaqueCard()
    }

    private var sourceLegend: some View {
        HStack(spacing: 12) {
            sourceSwatch("Lift", color: palette.lift)
            if showRunSplit {
                sourceSwatch("Cardio", color: palette.cardio)
            }
            sourceSwatch("Total", color: palette.total)
        }
    }

    private func sourceSwatch(_ title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func splitMeter(title: String, score: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(score.rounded()))")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.mutedFill)
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * min(max(score / 100, 0), 1)))
                }
            }
            .frame(height: 6)
        }
    }
}
