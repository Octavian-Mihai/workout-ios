import SwiftUI

struct ExercisePickerView: View {
    var onPick: (CatalogExercise) -> Void
    var onCustom: (String, [String], [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showCustom = false

    private var filtered: [(ExerciseCategory, [CatalogExercise])] {
        ExerciseCatalog.grouped().compactMap { category, items in
            let match = query.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(query) }
            return match.isEmpty ? nil : (category, match)
        }
    }

    var body: some View {
        List {
            ForEach(filtered, id: \.0) { category, items in
                Section(category.rawValue) {
                    ForEach(items) { item in
                        Button {
                            onPick(item)
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
                CustomExerciseForm { name, primary, secondary in
                    onCustom(name, primary, secondary)
                    dismiss()
                }
            }
        }
    }
}

struct CustomExerciseForm: View {
    var onSave: (String, [String], [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var primary: Set<String> = []
    @State private var secondary: Set<String> = []

    var body: some View {
        Form {
            TextField("Exercise name", text: $name)
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
                    onSave(name, Array(primary), Array(secondary))
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
