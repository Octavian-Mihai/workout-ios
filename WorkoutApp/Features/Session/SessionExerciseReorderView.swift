import SwiftUI
import UIKit

struct SessionExerciseReorderView: View {
    @ObservedObject var controller: SessionController
    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) private var theme

    var body: some View {
        NavigationStack {
            List {
                ForEach(controller.exercises) { exercise in
                    SessionExerciseReorderRow(exercise: exercise)
                }
                .onMove(perform: controller.moveExercises)
            }
            .environment(\.editMode, .constant(.active))
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.groupedBackground)
            .navigationTitle("Reorder exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SessionExerciseReorderRow: View {
    let exercise: DraftExercise
    @Environment(AppTheme.self) private var theme

    private var catalogMatch: CatalogExercise? {
        ExerciseCatalog.match(name: exercise.name)
    }

    private var assetName: String {
        if let catalogMatch {
            return ExerciseCatalog.imageAssetName(for: catalogMatch)
        }
        return "exercise-custom"
    }

    var body: some View {
        HStack(spacing: 12) {
            compactPhoto
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                if !exercise.primaryMuscles.isEmpty {
                    Text(exercise.primaryMuscles.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var compactPhoto: some View {
        if let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
        } else {
            ZStack {
                Color.white
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent.opacity(0.9))
            }
            .frame(width: 64, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
        }
    }
}
