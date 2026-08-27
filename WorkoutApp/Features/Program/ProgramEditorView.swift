import SwiftUI
import SwiftData

struct ProgramEditorView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("Name") {
                TextField("Program name", text: $program.name)
            }
            Section {
                Toggle("Active program", isOn: Binding(
                    get: { program.isActive },
                    set: { newValue in
                        let all = (try? modelContext.fetch(FetchDescriptor<Program>())) ?? []
                        for item in all {
                            item.isActive = newValue && item.uuid == program.uuid
                        }
                    }
                ))
                Text("Workouts cycle through these days in order. Empty workouts do not advance the rotation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Days (rotation)") {
                ForEach(program.orderedDays) { day in
                    NavigationLink {
                        DayEditorView(day: day)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.name)
                            Text("\(day.orderedExercises.count) exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove(perform: moveDays)
                .onDelete(perform: deleteDays)

                Button {
                    addDay()
                } label: {
                    Label("Add day", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .onDisappear { try? modelContext.save() }
    }

    private func addDay() {
        let index = program.days.count
        let day = ProgramDay(name: "Day \(index + 1)", sortIndex: index)
        day.program = program
        modelContext.insert(day)
        try? modelContext.save()
    }

    private func deleteDays(at offsets: IndexSet) {
        let ordered = program.orderedDays
        for offset in offsets {
            modelContext.delete(ordered[offset])
        }
        reindexDays()
    }

    private func moveDays(from source: IndexSet, to destination: Int) {
        var ordered = program.orderedDays
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, day) in ordered.enumerated() {
            day.sortIndex = index
        }
    }

    private func reindexDays() {
        for (index, day) in program.orderedDays.enumerated() {
            day.sortIndex = index
        }
    }
}

struct DayEditorView: View {
    @Bindable var day: ProgramDay
    @Environment(\.modelContext) private var modelContext
    @State private var showPicker = false

    var body: some View {
        List {
            Section("Day name") {
                TextField("Name", text: $day.name)
            }
            Section("Exercises") {
                ForEach(day.orderedExercises) { exercise in
                    DayExerciseEditorRow(exercise: exercise)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)

                Button {
                    showPicker = true
                } label: {
                    Label("Add exercise", systemImage: "plus")
                }
            }
        }
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                ExercisePickerView { catalog, sets, reps in
                    addExercise(
                        name: catalog.name,
                        primary: catalog.primaryNames,
                        secondary: catalog.secondaryNames,
                        sets: sets,
                        reps: reps
                    )
                } onCustom: { name, primary, secondary, sets, reps in
                    addExercise(name: name, primary: primary, secondary: secondary, sets: sets, reps: reps)
                }
            }
        }
    }

    private func addExercise(name: String, primary: [String], secondary: [String], sets: Int, reps: Int) {
        let item = DayExercise(
            name: name,
            primaryMuscles: primary,
            secondaryMuscles: secondary,
            targetSets: sets,
            targetReps: reps,
            sortIndex: day.exercises.count
        )
        item.day = day
        modelContext.insert(item)
        try? modelContext.save()
    }

    private func delete(at offsets: IndexSet) {
        let ordered = day.orderedExercises
        for offset in offsets {
            modelContext.delete(ordered[offset])
        }
        reindex()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = day.orderedExercises
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in ordered.enumerated() {
            item.sortIndex = index
        }
    }

    private func reindex() {
        for (index, item) in day.orderedExercises.enumerated() {
            item.sortIndex = index
        }
    }
}

struct DayExerciseEditorRow: View {
    @Bindable var exercise: DayExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.headline)
            Text(exercise.primaryMuscles.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
            Stepper("Sets: \(exercise.targetSets)", value: $exercise.targetSets, in: 1...12)
            Stepper("Reps: \(exercise.targetReps)", value: $exercise.targetReps, in: 1...30)
        }
        .padding(.vertical, 4)
    }
}
