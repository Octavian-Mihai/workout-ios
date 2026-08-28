import SwiftUI

struct RIRSelector: View {
    @Binding var rir: Int
    var accent: Color
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            ForEach(0...5, id: \.self) { value in
                Button {
                    rir = value
                } label: {
                    Text(RIRPalette.display(value))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 6 : 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(rir == value ? RIRPalette.color(for: value, accent: accent) : Theme.mutedFill)
                        )
                        .foregroundStyle(rir == value ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct RIRBadge: View {
    let rir: Int
    var accent: Color

    var body: some View {
        Text("RIR \(RIRPalette.display(rir))")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RIRPalette.color(for: rir, accent: accent))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct RIRDot: View {
    let rir: Int
    var size: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .fill(RIRPalette.color(for: rir, accent: .clear))
                .frame(width: size, height: size)
            Text(RIRPalette.display(rir))
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
        }
    }
}
