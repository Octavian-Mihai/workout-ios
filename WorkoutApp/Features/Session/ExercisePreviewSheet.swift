import SwiftUI

struct ExercisePreviewSheet: View {
    let exercise: CatalogExercise
    var isAdded: Bool = false
    var confirmTitle: String = "Add to program"
    var onConfirm: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme

    private var isViewOnly: Bool { onConfirm == nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ExercisePhotoView(
                        assetName: ExerciseCatalog.imageAssetName(for: exercise),
                        caption: exercise.name,
                        symbolName: "figure.strengthtraining.traditional",
                        showCaption: false
                    )

                    ExercisePreviewHeader(name: exercise.name, equipmentTitle: exercise.equipment.displayTitle)

                    exercisePreviewSection(title: "Primary muscles", body: exercise.primaryNames.joined(separator: ", "))

                    if !exercise.secondaryNames.isEmpty {
                        exercisePreviewSection(
                            title: "Secondary muscles",
                            body: exercise.secondaryNames.joined(separator: ", ")
                        )
                    }

                    exercisePreviewSection(title: "Coaching cues", body: exercise.cues)

                    if let onConfirm {
                        Button {
                            onConfirm()
                            dismiss()
                        } label: {
                            Text(isAdded ? "Added" : confirmTitle)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isAdded)
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .background(theme.groupedBackground)
            .navigationTitle(isViewOnly ? "Exercise details" : "Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isViewOnly ? "Close" : "Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Fallback details for custom / uncatalogued exercises. Never requires a catalog match.
struct CustomExerciseDetailsSheet: View {
    let name: String
    let equipment: ExerciseEquipment
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    var cues: String? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ExercisePhotoView(
                        assetName: "exercise-custom",
                        caption: name,
                        symbolName: "figure.strengthtraining.traditional",
                        showCaption: false
                    )

                    ExercisePreviewHeader(name: name, equipmentTitle: equipment.displayTitle)

                    if primaryMuscles.isEmpty {
                        exercisePreviewSection(title: "Primary muscles", body: "Not specified")
                    } else {
                        exercisePreviewSection(title: "Primary muscles", body: primaryMuscles.joined(separator: ", "))
                    }

                    if !secondaryMuscles.isEmpty {
                        exercisePreviewSection(
                            title: "Secondary muscles",
                            body: secondaryMuscles.joined(separator: ", ")
                        )
                    }

                    if let cues, !cues.isEmpty {
                        exercisePreviewSection(title: "Coaching cues", body: cues)
                    }
                }
                .padding(20)
            }
            .background(theme.groupedBackground)
            .navigationTitle("Exercise details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct ExercisePreviewHeader: View {
    let name: String
    let equipmentTitle: String
    @Environment(AppTheme.self) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.title2.weight(.bold))

            Text(equipmentTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.mutedFill)
                .clipShape(Capsule())
        }
    }
}

private func exercisePreviewSection(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        Text(body)
            .font(.body)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
