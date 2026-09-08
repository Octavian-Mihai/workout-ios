import SwiftUI

struct ExercisePreviewSheet: View {
    let exercise: CatalogExercise
    var isAdded: Bool = false
    var onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme

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

                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.title2.weight(.bold))

                        Text(exercise.equipment.displayTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.mutedFill)
                            .clipShape(Capsule())
                    }

                    previewSection(title: "Primary muscles", body: exercise.primaryNames.joined(separator: ", "))

                    if !exercise.secondaryNames.isEmpty {
                        previewSection(
                            title: "Secondary muscles",
                            body: exercise.secondaryNames.joined(separator: ", ")
                        )
                    }

                    previewSection(title: "Coaching cues", body: exercise.cues)

                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text(isAdded ? "Added" : "Add to program")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAdded)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(theme.groupedBackground)
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func previewSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(body)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
