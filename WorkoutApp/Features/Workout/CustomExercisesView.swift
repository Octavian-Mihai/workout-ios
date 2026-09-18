import SwiftUI
import SwiftData

struct CustomExercisesSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Program.createdAt) private var programs: [Program]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @AppStorage(WorkoutPageVisibility.customExercisesExpandedKey) private var isExpanded = false
    @State private var shareFallbackExercises: [CustomExerciseRecord]?
    @State private var pendingDeleteExercise: CustomExerciseRecord?

    private var exercises: [CustomExerciseRecord] {
        CustomExerciseCollector.collect(programs: programs, sessions: sessions)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                if exercises.isEmpty {
                    Text("No custom exercises yet. Add one from the exercise picker during a workout or while editing a program.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(16)
                        .opaqueCard()
                } else {
                    if exercises.count > 1 {
                        shareAllRow
                    }
                    exerciseList
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text("Custom exercises")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if !exercises.isEmpty {
                    Text("\(exercises.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.secondary)
        .sheet(isPresented: Binding(
            get: { shareFallbackExercises != nil },
            set: { if !$0 { shareFallbackExercises = nil } }
        )) {
            if let shareFallbackExercises {
                ShareFallbackSheet(exercises: shareFallbackExercises)
            }
        }
        .alert("Delete custom exercise?", isPresented: Binding(
            get: { pendingDeleteExercise != nil },
            set: { if !$0 { pendingDeleteExercise = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let exercise = pendingDeleteExercise {
                    deleteExercise(exercise)
                    pendingDeleteExercise = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteExercise = nil
            }
        } message: {
            if let exercise = pendingDeleteExercise {
                Text("\"\(exercise.name)\" will be removed from all programs and all logged sets for this exercise will be permanently deleted.")
            }
        }
    }

    private var exerciseList: some View {
        List {
            ForEach(exercises) { exercise in
                exerciseRow(exercise)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDeleteExercise = exercise
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .frame(height: CGFloat(exercises.count) * 108)
    }

    private func deleteExercise(_ exercise: CustomExerciseRecord) {
        CustomExerciseCollector.delete(
            name: exercise.name,
            programs: programs,
            sessions: sessions,
            in: modelContext
        )
    }

    private var shareAllRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Share all with developer")
                    .font(.subheadline.weight(.semibold))
                Text("Send every custom exercise for catalog review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ShareLink(
                item: ExerciseSubmissionService.formattedBody(exercises: exercises),
                preview: SharePreview("Custom exercises")
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.bordered)
            Button {
                if !ExerciseSubmissionService.openMail(exercises: exercises) {
                    shareFallbackExercises = exercises
                }
            } label: {
                Image(systemName: "envelope")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Email all custom exercises")
        }
        .padding(12)
        .opaqueCard()
    }

    private func exerciseRow(_ exercise: CustomExerciseRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                Text(exercise.equipment.displayTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !exercise.primaryMuscles.isEmpty {
                    Text("Primary: \(exercise.primaryMuscles.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !exercise.secondaryMuscles.isEmpty {
                    Text("Secondary: \(exercise.secondaryMuscles.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button {
                    if !ExerciseSubmissionService.openMail(
                        exerciseName: exercise.name,
                        equipment: exercise.equipment,
                        primaryMuscles: exercise.primaryMuscles,
                        secondaryMuscles: exercise.secondaryMuscles
                    ) {
                        shareFallbackExercises = [exercise]
                    }
                } label: {
                    Label("Email developer", systemImage: "envelope")
                }
                ShareLink(
                    item: ExerciseSubmissionService.formattedBody(exercises: [exercise]),
                    preview: SharePreview(exercise.name)
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Divider()
                Button(role: .destructive) {
                    pendingDeleteExercise = exercise
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 32, minHeight: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share \(exercise.name)")
        }
        .padding(12)
        .opaqueCard()
    }
}

private struct ShareFallbackSheet: View {
    let exercises: [CustomExerciseRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Mail isn’t available on this device. Share the details another way.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ShareLink(
                    item: ExerciseSubmissionService.formattedBody(exercises: exercises),
                    preview: SharePreview(exercises.count == 1 ? exercises[0].name : "Custom exercises")
                ) {
                    Label("Share exercise details", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(16)
            .navigationTitle("Share exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
