import SwiftUI

struct RIRSelector: View {
    @Binding var rir: Int
    var accent: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0...5, id: \.self) { value in
                Button {
                    rir = value
                } label: {
                    Text(RIRPalette.display(value))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
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
