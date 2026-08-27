import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var health: HealthKitService
    @Query private var programs: [Program]
    @Query private var sessions: [WorkoutSession]
    @Query private var weightEntries: [BodyWeightEntry]
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90
    @AppStorage("restTimerHaptics") private var restTimerHaptics = true
    @State private var showDeleteConfirm = false

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Accent") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(AccentOption.allCases) { option in
                            Button {
                                accentName = option.rawValue
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            if accentName == option.rawValue {
                                                Circle().strokeBorder(Color.primary, lineWidth: 2)
                                            }
                                        }
                                    Text(option.title)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Theme.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Appearance") {
                    Picker("Background", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Cards use opaque fills and borders — no glass or ultra-thin materials.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Units") {
                    Picker("Weight", selection: $weightUnitRaw) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.title).tag(unit.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Lifting loads and body weight are stored in kilograms and converted for display.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Distance", selection: $distanceUnitRaw) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.title).tag(unit.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Running distance and pace use this unit. Values from Health stay in meters internally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Session") {
                    Stepper("Default rest \(defaultRestSeconds)s", value: $defaultRestSeconds, in: 15...300, step: 15)
                    Toggle("Rest-timer haptics", isOn: $restTimerHaptics)
                }

                Section("Body weight") {
                    NavigationLink("Weight log") {
                        BodyWeightLogView()
                    }
                }

                Section("Health") {
                    Text("Running is read from Apple Health. Strength sessions stay in this app and are not written to HealthKit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Re-request HealthKit access") {
                        Task { await health.requestAndLoad() }
                    }
                    Button("Open Apple Health") {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section("Privacy") {
                    NavigationLink("What we store") {
                        PrivacyInfoView()
                    }
                }

                Section("Data") {
                    Button("Delete all local data", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(versionLabel)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.groupedBackground)
            .navigationTitle("Settings")
            .alert("Delete all local data?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteAllLocalData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes programs, workout history, and body-weight entries from this device. Apple Health data is not deleted.")
            }
        }
    }

    private func deleteAllLocalData() {
        for item in programs { modelContext.delete(item) }
        for item in sessions { modelContext.delete(item) }
        for item in weightEntries { modelContext.delete(item) }
        try? modelContext.save()
    }
}

struct PrivacyInfoView: View {
    var body: some View {
        List {
            Section("On this device") {
                Text("Programs, workout sessions, sets (weight, reps, RIR), and body-weight entries are stored locally with SwiftData. Nothing is uploaded to a server.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Apple Health") {
                Text("Running workouts, GPS routes, distance, and heart rate are read only. This app never writes strength sessions or other data to HealthKit.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Encryption") {
                Text("The app does not use non-exempt encryption. Workout data stays in the device’s standard app container.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BodyWeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var entries: [BodyWeightEntry]
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @State private var showAdd = false

    private var unit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }

    var body: some View {
        List {
            if entries.isEmpty {
                Text("No entries yet. Log body weight to keep a simple history. Relative volume can use this later.")
                    .foregroundStyle(.secondary)
            }
            ForEach(entries) { entry in
                HStack {
                    Text(Formatters.shortDate.string(from: entry.date))
                    Spacer()
                    Text(unit.format(entry.kilograms))
                        .monospacedDigit()
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(entries[index])
                }
            }
        }
        .navigationTitle("Weight log")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                AddBodyWeightView { kg, date in
                    let entry = BodyWeightEntry(date: date, kilograms: kg)
                    modelContext.insert(entry)
                    try? modelContext.save()
                }
            }
        }
    }
}

struct AddBodyWeightView: View {
    var onSave: (Double, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @State private var value: Double = 80
    @State private var date = Date()

    private var unit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }

    var body: some View {
        Form {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            HStack {
                Text("Weight (\(unit.rawValue))")
                Spacer()
                TextField("Weight", value: $value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        }
        .navigationTitle("Add entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(unit.toKg(value), date)
                    dismiss()
                }
            }
        }
    }
}
