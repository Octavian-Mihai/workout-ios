import SwiftUI
import Charts

struct StressLegendView: View {
    var compact: Bool = false
    var highlightScore: Double? = nil

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

struct StressMeter: View {
    let title: String
    let score: Double
    let accent: Color
    var compact: Bool = false

    private var band: StressBand { StressCalculator.band(for: score) }

    private var color: Color {
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
                        .fill(Theme.mutedFill)
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

struct TodayStressCard: View {
    let estimate: StressEstimate
    var showSplit: Bool = false
    var trend: [DailyStress] = []
    let accent: Color
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 12) {
            StressMeter(title: "Today’s stress", score: estimate.total, accent: accent, compact: compact)
            if showSplit {
                HStack(spacing: 16) {
                    splitMeter(title: "Lift", score: estimate.lift)
                    splitMeter(title: "Run", score: estimate.run)
                }
            }
            if !compact, trend.count >= 2 {
                Chart(trend) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Stress", point.total)
                    )
                    .foregroundStyle(accent)
                    PointMark(
                        x: .value("Day", point.date),
                        y: .value("Stress", point.total)
                    )
                    .foregroundStyle(accent)
                }
                .frame(height: 120)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
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

    private func splitMeter(title: String, score: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(score.rounded()))")
                    .font(.caption.monospacedDigit().weight(.semibold))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.mutedFill)
                    Capsule()
                        .fill(accent)
                        .frame(width: max(4, geo.size.width * min(max(score / 100, 0), 1)))
                }
            }
            .frame(height: 6)
        }
    }
}
