import SwiftUI

struct SessionInputKeyboard: View {
    enum Mode {
        case weight
        case reps
    }

    let mode: Mode
    let accent: Color
    let unit: WeightUnit
    let equipment: ExerciseEquipment
    @Binding var weightText: String
    @Binding var repsText: String
    @Binding var rir: Int
    var onDismiss: () -> Void
    var onNext: () -> Void
    var onCompleteSet: () -> Void

    @AppStorage(EquipmentSettings.barbellBarKgKey) private var barbellBarKg = EquipmentSettings.defaultBarKg
    @AppStorage(EquipmentSettings.barbellBarLbKey) private var barbellBarLb = EquipmentSettings.defaultBarLb
    @AppStorage(EquipmentSettings.ftIncrementKgKey) private var ftIncrementKg = EquipmentSettings.defaultFTKg
    @AppStorage(EquipmentSettings.ftIncrementLbKey) private var ftIncrementLb = EquipmentSettings.defaultFTLb

    private let rowHeight: CGFloat = 38
    private let gap: CGFloat = 5
    private let numberKeys: [[String?]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    private var showsPlates: Bool {
        mode == .weight && (equipment == .barbell || equipment == .functionalTrainer)
    }

    private var baseWeight: Double {
        if equipment == .functionalTrainer {
            return unit == .kg ? ftIncrementKg : ftIncrementLb
        }
        return unit == .kg ? barbellBarKg : barbellBarLb
    }

    private var baseStep: Double {
        equipment == .functionalTrainer
            ? EquipmentSettings.ftStep(for: unit)
            : EquipmentSettings.barStep(for: unit)
    }

    private var baseLabel: String {
        equipment == .functionalTrainer ? "Base" : "Bar"
    }

    private var breakdown: PlateBreakdown? {
        guard showsPlates else { return nil }
        let total = Double(weightText) ?? 0
        return PlateCalculator.calculate(
            total: total,
            base: baseWeight,
            unit: unit,
            equipment: equipment
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            if showsPlates, let breakdown {
                plateStrip(breakdown)
            }
            if mode == .reps {
                RIRSelector(rir: $rir, accent: accent, compact: true)
            }
            padGrid
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Theme.cardFill.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var padGrid: some View {
        HStack(alignment: .top, spacing: gap) {
            VStack(spacing: gap) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<3, id: \.self) { column in
                            padCell(row: row, column: column)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: gap) {
                actionKey(
                    title: "Dismiss Keyboard",
                    fill: Theme.mutedFill,
                    foreground: .primary,
                    action: onDismiss
                )
                .frame(height: rowHeight * 2 + gap)

                if mode == .weight {
                    actionKey(
                        title: "Next",
                        fill: accent,
                        foreground: .white,
                        action: onNext
                    )
                    .frame(height: rowHeight * 2 + gap)
                } else {
                    actionKey(
                        title: "Complete Set",
                        fill: accent,
                        foreground: .white,
                        action: onCompleteSet
                    )
                    .frame(height: rowHeight * 2 + gap)
                }
            }
            .containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: gap)
        }
    }

    @ViewBuilder
    private func padCell(row: Int, column: Int) -> some View {
        let token = numberKeys[row][column] ?? ""
        if row == 3 && column == 0 && mode == .reps {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: rowHeight)
        } else if token == "⌫" {
            Button(action: backspace) {
                Image(systemName: "delete.backward")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 26)
                    .background(Theme.mutedFill)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
        } else if token == "." {
            numberKey(".", action: appendDecimal)
        } else {
            numberKey(token) { appendDigit(token) }
        }
    }

    private func numberKey(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.monospacedDigit().weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: rowHeight)
                .background(Theme.mutedFill)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private func actionKey(title: String, fill: Color, foreground: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(fill)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
    }

    private func plateStrip(_ breakdown: PlateBreakdown) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(plateHeadline(breakdown))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if breakdown.remainder > 0.001, !breakdown.isBelowBase {
                    Text("rem \(Formatters.trimmedNumber(breakdown.remainder)) \(unit.rawValue)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                Button {
                    adjustBase(-baseStep)
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                        .background(Theme.mutedFill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Text("\(baseLabel) \(Formatters.trimmedNumber(baseWeight))")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                Button {
                    adjustBase(baseStep)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                        .background(Theme.mutedFill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private func plateHeadline(_ breakdown: PlateBreakdown) -> String {
        if breakdown.isBelowBase {
            return "Below \(baseLabel.lowercased())"
        }
        if breakdown.perSide < 0.001 {
            return "\(baseLabel) only"
        }
        let plates = breakdown.compactPlates
        if plates.isEmpty || plates == "—" {
            return "Per side rem \(Formatters.trimmedNumber(breakdown.remainder))"
        }
        return "Per side \(plates)"
    }

    private func adjustBase(_ delta: Double) {
        let minimum: Double = equipment == .functionalTrainer ? (unit == .kg ? 0.5 : 1) : (unit == .kg ? 5 : 15)
        let maximum: Double = equipment == .functionalTrainer ? (unit == .kg ? 20 : 45) : (unit == .kg ? 40 : 70)
        let next = Swift.min(Swift.max(baseWeight + delta, minimum), maximum)
        if equipment == .functionalTrainer {
            if unit == .kg {
                ftIncrementKg = next
            } else {
                ftIncrementLb = next
            }
        } else if unit == .kg {
            barbellBarKg = next
        } else {
            barbellBarLb = next
        }
    }

    private func appendDigit(_ digit: String) {
        if mode == .weight {
            var text = weightText
            if text == "0" { text = digit }
            else if text.count < 7 { text += digit }
            weightText = text
        } else {
            var text = repsText
            if text == "0" { text = digit }
            else if text.count < 3 { text += digit }
            repsText = text
        }
    }

    private func appendDecimal() {
        guard mode == .weight else { return }
        var text = weightText
        if text.isEmpty { text = "0." }
        else if !text.contains(".") { text += "." }
        weightText = text
    }

    private func backspace() {
        if mode == .weight {
            if !weightText.isEmpty {
                weightText.removeLast()
            }
        } else if !repsText.isEmpty {
            repsText.removeLast()
        }
    }
}
