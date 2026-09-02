import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppTheme.self) private var appTheme
    @EnvironmentObject private var health: HealthKitService
    @Query private var programs: [Program]
    @Query private var sessions: [WorkoutSession]
    @Query private var weightEntries: [BodyWeightEntry]
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90
    @AppStorage("restTimerHaptics") private var restTimerHaptics = true
    @AppStorage(EquipmentSettings.barbellBarKgKey) private var barbellBarKg = EquipmentSettings.defaultBarKg
    @AppStorage(EquipmentSettings.barbellBarLbKey) private var barbellBarLb = EquipmentSettings.defaultBarLb
    @AppStorage(EquipmentSettings.ftIncrementKgKey) private var ftIncrementKg = EquipmentSettings.defaultFTKg
    @AppStorage(EquipmentSettings.ftIncrementLbKey) private var ftIncrementLb = EquipmentSettings.defaultFTLb
    @AppStorage(InfoPageVisibility.showTodayStressKey) private var showTodayStress = true
    @AppStorage(InfoPageVisibility.showTonnageKey) private var showTonnage = true
    @AppStorage(InfoPageVisibility.showVolumeChartsKey) private var showVolumeCharts = true
    @AppStorage(InfoPageVisibility.showEstimated1RMKey) private var showEstimated1RM = true
    @AppStorage(InfoPageVisibility.showIntensityMapKey) private var showIntensityMap = true
    @AppStorage(HealthKitService.writeStrengthToHealthKitKey) private var writeStrengthToHealthKit = false
    @State private var showDeleteConfirm = false
    @State private var showImporter = false
    @State private var dataError: String?
    @State private var showDataError = false

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        @Bindable var theme = appTheme

        NavigationStack {
            List {
                Section("Accent") {
                    AccentPickerDashboard(accentName: $theme.accentName, customHex: $theme.customAccentHex)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Appearance") {
                    Picker("Mode", selection: $theme.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    BackgroundPickerDashboard(
                        backgroundName: $theme.backgroundName,
                        customHex: $theme.customBackgroundHex
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

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

                Section("Info page") {
                    Toggle("Show today’s stress", isOn: $showTodayStress)
                    Toggle("Show tonnage / muscle breakdown", isOn: $showTonnage)
                    Toggle("Show volume charts", isOn: $showVolumeCharts)
                    Toggle("Show estimated 1RM", isOn: $showEstimated1RM)
                    Toggle("Show intensity map", isOn: $showIntensityMap)
                    Text("Hidden sections do not appear on the Info tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Equipment") {
                    if unit == .kg {
                        Stepper(
                            "Barbell bar \(Formatters.trimmedNumber(barbellBarKg)) kg",
                            value: $barbellBarKg,
                            in: 5...40,
                            step: 2.5
                        )
                        Stepper(
                            "FT increment \(Formatters.trimmedNumber(ftIncrementKg)) kg",
                            value: $ftIncrementKg,
                            in: 0.5...20,
                            step: 0.5
                        )
                    } else {
                        Stepper(
                            "Barbell bar \(Formatters.trimmedNumber(barbellBarLb)) lb",
                            value: $barbellBarLb,
                            in: 15...70,
                            step: 5
                        )
                        Stepper(
                            "FT increment \(Formatters.trimmedNumber(ftIncrementLb)) lb",
                            value: $ftIncrementLb,
                            in: 1...45,
                            step: 2.5
                        )
                    }
                    Text("The plate calculator subtracts bar or functional-trainer base weight, then shows plates per side.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Body weight") {
                    NavigationLink("Weight log") {
                        BodyWeightLogView()
                    }
                }

                Section("Health") {
                    Toggle("Write finished workouts to Apple Health", isOn: $writeStrengthToHealthKit)
                    Text("When this is on, finishing a strength session adds a Traditional Strength Training workout to Apple Health. When it’s off, sessions stay in this app only. Running is read from Health. Body weight is read from and saved to Health.")
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
                    ShareLink(
                        item: WorkoutBackupService.make(
                            programs: programs,
                            sessions: sessions,
                            weights: weightEntries
                        ),
                        preview: SharePreview("Workout data")
                    ) {
                        Label("Export workout data", systemImage: "square.and.arrow.up")
                    }
                    Button("Import workout data") {
                        showImporter = true
                    }
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
            .background(theme.groupedBackground)
            .navigationTitle("Settings")
            .alert("Delete all local data?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteAllLocalData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes programs, workout history, and body-weight entries from this device. Apple Health data is not deleted.")
            }
            .onChange(of: writeStrengthToHealthKit) { _, isOn in
                if isOn {
                    Task { await health.requestAndLoad() }
                }
            }
            .alert("Couldn’t import workout data", isPresented: $showDataError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(dataError ?? "The file could not be read.")
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importWorkoutData(from: url)
                case .failure(let error):
                    dataError = error.localizedDescription
                    showDataError = true
                }
            }
        }
    }

    private func importWorkoutData(from url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let data = try Data(contentsOf: url)
            let backup = try WorkoutBackupService.decode(data)
            try WorkoutBackupService.importBackup(
                backup,
                context: modelContext,
                existingPrograms: programs,
                existingSessions: sessions,
                existingWeights: weightEntries
            )
        } catch {
            dataError = error.localizedDescription
            showDataError = true
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
                Text("Running workouts, GPS routes, distance, and heart rate are read only. Body weight is read from and written to Apple Health when you use the weight log. Finished strength sessions are written to Health as Traditional Strength Training workouts only if you turn on writing workouts in Settings.")
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
    @EnvironmentObject private var health: HealthKitService
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
                    Task { await health.saveBodyMass(kilograms: kg, date: date) }
                }
            }
        }
        .task {
            await mergeHealthKitWeights()
        }
    }

    private func mergeHealthKitWeights() async {
        do {
            let samples = try await health.fetchBodyMass()
            let calendar = Calendar.current
            var added = false
            for sample in samples {
                let exists = entries.contains { entry in
                    calendar.isDate(entry.date, inSameDayAs: sample.date)
                        && abs(entry.kilograms - sample.kilograms) < 0.05
                }
                if !exists {
                    modelContext.insert(BodyWeightEntry(date: sample.date, kilograms: sample.kilograms))
                    added = true
                }
            }
            if added {
                try modelContext.save()
            }
        } catch {
            health.lastError = error.localizedDescription
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
