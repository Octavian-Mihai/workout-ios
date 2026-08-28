import SwiftUI
import UIKit

struct AccentPickerDashboard: View {
    @Binding var accentName: String
    @Binding var customHex: String

    @State private var showCustomPicker = false

    private var activeColor: Color {
        AccentTheme.color(accentName: accentName, customHex: customHex)
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AccentOption.presets) { option in
                presetSwatch(option)
            }

            customButton
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showCustomPicker) {
            CustomAccentPickerSheet(
                accentName: $accentName,
                customHex: $customHex,
                initialColor: activeColor
            )
        }
    }

    private func presetSwatch(_ option: AccentOption) -> some View {
        Button {
            accentName = option.rawValue
        } label: {
            Circle()
                .fill(option.color)
                .frame(height: 40)
                .overlay {
                    if accentName == option.rawValue {
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: 2.5)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var customButton: some View {
        Button {
            showCustomPicker = true
        } label: {
            Group {
                if AccentTheme.isCustom(accentName) {
                    Circle()
                        .fill(activeColor)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.primary, lineWidth: 2.5)
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                } else {
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .background(Circle().fill(Theme.mutedFill))
                        .overlay {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Custom accent color")
    }
}

private struct CustomAccentPickerSheet: View {
    @Binding var accentName: String
    @Binding var customHex: String
    let initialColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var draftColor: Color

    init(accentName: Binding<String>, customHex: Binding<String>, initialColor: Color) {
        _accentName = accentName
        _customHex = customHex
        self.initialColor = initialColor
        _draftColor = State(initialValue: initialColor)
    }

    var body: some View {
        SystemAccentColorPicker(color: $draftColor, onSave: saveAndClose)
            .ignoresSafeArea()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
    }

    private func saveAndClose() {
        customHex = draftColor.toHex()
        accentName = AccentTheme.customName
        dismiss()
    }
}

/// Native iOS color picker (spectrum, sliders, grip) with a Save bar button.
private struct SystemAccentColorPicker: UIViewControllerRepresentable {
    @Binding var color: Color
    var onSave: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.selectedColor = UIColor(color)
        picker.delegate = context.coordinator

        let saveItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.didTapSave)
        )
        picker.navigationItem.rightBarButtonItem = saveItem

        let navigation = UINavigationController(rootViewController: picker)
        navigation.navigationBar.prefersLargeTitles = false
        return navigation
    }

    func updateUIViewController(_ navigation: UINavigationController, context: Context) {
        guard let picker = navigation.viewControllers.first as? UIColorPickerViewController else { return }
        let uiColor = UIColor(color)
        if !picker.selectedColor.isEqual(uiColor) {
            picker.selectedColor = uiColor
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: SystemAccentColorPicker

        init(parent: SystemAccentColorPicker) {
            self.parent = parent
        }

        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            parent.color = Color(viewController.selectedColor)
        }

        @objc func didTapSave() {
            parent.onSave()
        }
    }
}
