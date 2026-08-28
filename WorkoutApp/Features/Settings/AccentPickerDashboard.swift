import SwiftUI

struct AccentPickerDashboard: View {
    @Binding var accentName: String

    private var selected: AccentOption {
        AccentOption.resolved(rawValue: accentName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Drag across swatches or tap to preview your accent across the app.")
                .font(.caption)
                .foregroundStyle(.secondary)

            AccentPreviewMock(accent: selected.color)
                .animation(.easeInOut(duration: 0.2), value: accentName)

            DraggableAccentStrip(accentName: $accentName)
        }
        .padding(.vertical, 4)
    }
}

private struct AccentPreviewMock: View {
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Overview")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(accent)
            }

            HStack(spacing: 6) {
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(i.isMultiple(of: 3) ? accent : accent.opacity(0.25 + Double(i % 3) * 0.15))
                        .frame(width: 10, height: 10)
                }
            }

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent.opacity(0.15))
                    .frame(height: 36)
                    .overlay(alignment: .leading) {
                        Text("Next workout")
                            .font(.caption.weight(.semibold))
                            .padding(.leading, 10)
                    }
                Button {} label: {
                    Text("Start")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Theme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1.5)
        )
    }
}

private struct DraggableAccentStrip: View {
    @Binding var accentName: String

    private let options = AccentOption.selectable

    var body: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / CGFloat(max(options.count, 1))

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(options) { option in
                        Button {
                            accentName = option.rawValue
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if accentName == option.rawValue {
                                            Circle()
                                                .strokeBorder(Color.primary, lineWidth: 2.5)
                                            Image(systemName: "checkmark")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                Text(option.title)
                                    .font(.caption2)
                                    .foregroundStyle(accentName == option.rawValue ? Color.primary : Color.secondary)
                            }
                            .frame(width: cellWidth)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                selectionRing(cellWidth: cellWidth)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        pick(at: value.location.x, cellWidth: cellWidth)
                    }
            )
            .simultaneousGesture(
                TapGesture().onEnded {}
            )
        }
        .frame(height: 72)
    }

    @ViewBuilder
    private func selectionRing(cellWidth: CGFloat) -> some View {
        if let index = options.firstIndex(where: { $0.rawValue == accentName }) {
            Circle()
                .strokeBorder(Color.primary.opacity(0.25), lineWidth: 2)
                .frame(width: 44, height: 44)
                .offset(x: cellWidth * CGFloat(index) + (cellWidth - 44) / 2, y: -4)
                .animation(.easeOut(duration: 0.15), value: accentName)
                .allowsHitTesting(false)
        }
    }

    private func pick(at x: CGFloat, cellWidth: CGFloat) {
        guard cellWidth > 0 else { return }
        let index = min(max(Int(x / cellWidth), 0), options.count - 1)
        accentName = options[index].rawValue
    }
}
