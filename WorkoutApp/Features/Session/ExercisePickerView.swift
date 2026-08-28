import SwiftUI

struct ExercisePickerView: View {
    var onPick: (CatalogExercise) -> Void
    var onCustom: (String, [String], [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage(AccentTheme.customHexKey) private var customAccentHex = AccentTheme.defaultCustomHex
    @State private var query = ""
    @State private var showCustom = false
    @State private var categoryFilter: ExerciseCategory?
    @State private var equipmentFilter: ExerciseEquipment?
    @State private var muscleFilter: MuscleGroup?

    private var accent: Color {
        AccentTheme.color(accentName: accentName, customHex: customAccentHex)
    }

    private var filtered: [CatalogExercise] {
        ExerciseCatalog.all.filter { item in
            let matchesQuery = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || item.primaryNames.contains { $0.localizedCaseInsensitiveContains(query) }
            let matchesCategory = categoryFilter == nil || item.category == categoryFilter
            let matchesEquipment = equipmentFilter == nil || item.equipment == equipmentFilter
            let matchesMuscle = muscleFilter == nil
                || item.primary.contains(muscleFilter!)
                || item.secondary.contains(muscleFilter!)
            return matchesQuery && matchesCategory && matchesEquipment && matchesMuscle
        }
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var groupedFiltered: [(ExerciseCategory, [CatalogExercise])] {
        ExerciseCategory.allCases.compactMap { category in
            let items = filtered.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            List {
                if filtered.isEmpty {
                    Text("No exercises match your search or filters.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(groupedFiltered, id: \.0) { category, items in
                        Section(category.rawValue) {
                            ForEach(items) { item in
                                Button {
                                    onPick(item)
                                    dismiss()
                                } label: {
                                    ExercisePickerRow(exercise: item)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(Theme.groupedBackground)
        .searchable(text: $query, prompt: "Search exercises or muscles")
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

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", selected: categoryFilter == nil && equipmentFilter == nil && muscleFilter == nil) {
                    categoryFilter = nil
                    equipmentFilter = nil
                    muscleFilter = nil
                }

                Menu {
                    Button("All categories") { categoryFilter = nil }
                    Divider()
                    ForEach(ExerciseCategory.allCases) { cat in
                        Button(cat.rawValue) { categoryFilter = cat }
                    }
                } label: {
                    FilterChipLabel(
                        title: categoryFilter?.rawValue ?? "Category",
                        selected: categoryFilter != nil
                    )
                }

                Menu {
                    Button("All equipment") { equipmentFilter = nil }
                    Divider()
                    ForEach(ExerciseEquipment.allCases) { eq in
                        Button(equipmentTitle(eq)) { equipmentFilter = eq }
                    }
                } label: {
                    FilterChipLabel(
                        title: equipmentFilter.map(equipmentTitle) ?? "Equipment",
                        selected: equipmentFilter != nil
                    )
                }

                Menu {
                    Button("All muscles") { muscleFilter = nil }
                    Divider()
                    ForEach(MuscleGroup.allCases) { muscle in
                        Button(muscle.rawValue) { muscleFilter = muscle }
                    }
                } label: {
                    FilterChipLabel(
                        title: muscleFilter?.rawValue ?? "Muscle",
                        selected: muscleFilter != nil
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Theme.cardFill)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func equipmentTitle(_ equipment: ExerciseEquipment) -> String {
        switch equipment {
        case .barbell: return "Barbell"
        case .functionalTrainer: return "Cable / FT"
        case .other: return "Other"
        }
    }
}

private struct ExercisePickerRow: View {
    let exercise: CatalogExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.name)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            HStack(spacing: 8) {
                Text(exercise.primaryNames.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                equipmentBadge
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var equipmentBadge: some View {
        let label: String = {
            switch exercise.equipment {
            case .barbell: return "BB"
            case .functionalTrainer: return "FT"
            case .other: return "Other"
            }
        }()
        Text(label)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.mutedFill)
            .clipShape(Capsule())
    }
}

private struct FilterChip: View {
    let title: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            FilterChipLabel(title: title, selected: selected)
        }
        .buttonStyle(.plain)
    }
}

private struct FilterChipLabel: View {
    let title: String
    let selected: Bool

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selected ? Color.accentColor : Theme.mutedFill)
            .clipShape(Capsule())
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
