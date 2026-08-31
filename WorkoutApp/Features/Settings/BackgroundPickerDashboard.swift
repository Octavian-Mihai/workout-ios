import SwiftUI
import UIKit

struct BackgroundPickerDashboard: View {
    @Binding var backgroundName: String
    @Binding var customHex: String

    @Environment(AppTheme.self) private var theme
    @State private var showCustomPicker = false

    private var activeColor: Color {
        BackgroundTheme.baseColor(backgroundName: backgroundName, customHex: customHex)
            ?? Color(.systemGroupedBackground)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BackgroundOption.presets) { option in
                presetSwatch(option)
            }

            customButton
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showCustomPicker) {
            CustomBackgroundPickerSheet(
                backgroundName: $backgroundName,
                customHex: $customHex,
                initialColor: activeColor
            )
        }
    }

    private func presetSwatch(_ option: BackgroundOption) -> some View {
        Button {
            backgroundName = option.rawValue
        } label: {
            Group {
                if option == .system {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.92), Color(white: 0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    Circle()
                        .fill(option.color)
                }
            }
            .frame(height: 36)
            .overlay {
                if backgroundName == option.rawValue {
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: 2.5)
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(option.title)
    }

    private var customButton: some View {
        Button {
            showCustomPicker = true
        } label: {
            Group {
                if BackgroundTheme.isCustom(backgroundName) {
                    Circle()
                        .fill(activeColor)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.primary, lineWidth: 2.5)
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                } else {
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .background(Circle().fill(theme.mutedFill))
                        .overlay {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Custom background color")
    }
}

private struct CustomBackgroundPickerSheet: View {
    @Binding var backgroundName: String
    @Binding var customHex: String
    let initialColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var draftColor: Color

    init(backgroundName: Binding<String>, customHex: Binding<String>, initialColor: Color) {
        _backgroundName = backgroundName
        _customHex = customHex
        self.initialColor = initialColor
        _draftColor = State(initialValue: initialColor)
    }

    var body: some View {
        SystemBackgroundColorPicker(color: $draftColor, onSave: saveAndClose)
            .ignoresSafeArea()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
    }

    private func saveAndClose() {
        customHex = draftColor.toHex()
        backgroundName = BackgroundTheme.customName
        dismiss()
    }
}

private struct SystemBackgroundColorPicker: UIViewControllerRepresentable {
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
        var parent: SystemBackgroundColorPicker

        init(parent: SystemBackgroundColorPicker) {
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
