import SwiftUI

struct StressLegendView: View {
    var compact: Bool = false

    private let bands: [(String, String, Color)] = [
        ("0–30", "Recovery / easy", Color(red: 0.30, green: 0.72, blue: 0.48)),
        ("31–55", "Productive", Color(red: 0.25, green: 0.55, blue: 0.90)),
        ("56–75", "High — watch sleep/fatigue", Color(red: 0.95, green: 0.58, blue: 0.18)),
        ("76–100", "Very high — consider backing off", Color(red: 0.90, green: 0.25, blue: 0.28))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            Text("Stress scale")
                .font(.subheadline.weight(.semibold))
            ForEach(Array(bands.enumerated()), id: \.offset) { _, band in
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(band.2)
                        .frame(width: 8, height: compact ? 28 : 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(band.0)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                        Text(band.1)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .tint(accent)
                Spacer()
                Text("\(Int(score.rounded()))")
                    .font(.title2.monospacedDigit().weight(.bold))
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
            .frame(height: 8)
            Text(band.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
