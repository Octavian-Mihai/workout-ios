import SwiftUI

struct ExercisePickerView: View {
    var onPick: (CatalogExercise, Int, Int) -> Void
    var onCustom: (String, [String], [String], Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showCustom = false
    @State private var targetSets = 3
    @State private var targetReps = 8

    private var filtered: [(ExerciseCategory, [CatalogExercise])] {
        ExerciseCatalog.grouped().compactMap { category, items in
            let match = query.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(query) }
            return match.isEmpty ? nil : (category, match)
        }
    }

    var body: some View {
        List {
            Section {
                Stepper("Target sets: \(targetSets)", value: $targetSets, in: 1...12)
                Stepper("Target reps: \(targetReps)", value: $targetReps, in: 1...30)
            }
            ForEach(filtered, id: \.0) { category, items in
                Section(category.rawValue) {
                    ForEach(items) { item in
                        Button {
                            onPick(item, targetSets, targetReps)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                Text(item.primaryNames.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query)
        .navigationTitle("Add exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Custom") { showCustom = true }
            }
        }
        .sheet(isPresented: $showCustom) {
            NavigationStack {
                CustomExerciseForm(defaultSets: targetSets, defaultReps: targetReps) { name, primary, secondary, sets, reps in
                    onCustom(name, primary, secondary, sets, reps)
                    dismiss()
                }
            }
        }
    }
}

struct CustomExerciseForm: View {
    var defaultSets: Int
    var defaultReps: Int
    var onSave: (String, [String], [String], Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var primary: Set<String> = []
    @State private var secondary: Set<String> = []
    @State private var sets: Int
    @State private var reps: Int

    init(defaultSets: Int, defaultReps: Int, onSave: @escaping (String, [String], [String], Int, Int) -> Void) {
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.onSave = onSave
        _sets = State(initialValue: defaultSets)
        _reps = State(initialValue: defaultReps)
    }

    var body: some View {
        Form {
            TextField("Exercise name", text: $name)
            Stepper("Sets: \(sets)", value: $sets, in: 1...12)
            Stepper("Reps: \(reps)", value: $reps, in: 1...30)
            Section("Primary muscles") {
                ForEach(MuscleGroup.allCases) { muscle in
                    Toggle(muscle.rawValue, isOn: binding(muscle.rawValue, in: $primary))
                }
            }
            Section("Secondary muscles") {
                ForEach(MuscleGroup.allCases) { muscle in
                    Toggle(muscle.rawValue, isOn: binding(muscle.rawValue, in: $secondary))
                }
            }
        }
        .navigationTitle("Custom exercise")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    onSave(name, Array(primary), Array(secondary), sets, reps)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func binding(_ value: String, in set: Binding<Set<String>>) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(value) },
            set: { isOn in
                if isOn { set.wrappedValue.insert(value) } else { set.wrappedValue.remove(value) }
            }
        )
    }
}
