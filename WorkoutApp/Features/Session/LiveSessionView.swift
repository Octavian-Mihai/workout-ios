import SwiftUI
import SwiftData
import Combine

struct DraftExercise: Identifiable {
    let id: UUID
    var name: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var targetSets: Int
    var targetReps: Int
    var logged: [DraftSet]

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        targetSets: Int,
        targetReps: Int,
        logged: [DraftSet] = []
    ) {
        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.logged = logged
    }
}

struct DraftSet: Identifiable {
    let id: UUID
    var weightKg: Double
    var reps: Int
    var rir: Int

    init(id: UUID = UUID(), weightKg: Double, reps: Int, rir: Int) {
        self.id = id
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
    }
}

@MainActor
final class SessionController: ObservableObject {
    @Published var exercises: [DraftExercise]
    @Published var restDuration: Int
    @Published var restRemaining: Int
    @Published var timerRunning = false
    @Published var startedAt: Date

    let program: Program?
    let programDay: ProgramDay?
    let isEmpty: Bool

    init(program: Program?, programDay: ProgramDay?, defaultRest: Int = 90) {
        self.program = program
        self.programDay = programDay
        self.isEmpty = programDay == nil
        self.restDuration = defaultRest
        self.restRemaining = defaultRest
        self.startedAt = Date()
        if let day = programDay {
            self.exercises = day.orderedExercises.map { item in
                DraftExercise(
                    name: item.name,
                    primaryMuscles: item.primaryMuscles,
                    secondaryMuscles: item.secondaryMuscles,
                    targetSets: item.targetSets,
                    targetReps: item.targetReps
                )
            }
        } else {
            self.exercises = []
        }
    }

    var loggedSetCount: Int {
        exercises.reduce(0) { $0 + $1.logged.count }
    }

    func tick() {
        guard timerRunning, restRemaining > 0 else { return }
        restRemaining -= 1
        if restRemaining == 0 {
            timerRunning = false
        }
    }

    func startRest() {
        restRemaining = restDuration
        timerRunning = true
    }

    func resetRest() {
        restRemaining = restDuration
        timerRunning = false
    }

    func logSet(exerciseID: UUID, weightKg: Double, reps: Int, rir: Int) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].logged.append(DraftSet(weightKg: weightKg, reps: reps, rir: rir))
        startRest()
    }

    func removeSet(exerciseID: UUID, setID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].logged.removeAll { $0.id == setID }
    }

    func addExercise(_ catalog: CatalogExercise, sets: Int, reps: Int) {
        exercises.append(
            DraftExercise(
                name: catalog.name,
                primaryMuscles: catalog.primaryNames,
                secondaryMuscles: catalog.secondaryNames,
                targetSets: sets,
                targetReps: reps
            )
        )
    }

    func addCustom(name: String, primary: [String], secondary: [String], sets: Int, reps: Int) {
        exercises.append(
            DraftExercise(
                name: name,
                primaryMuscles: primary,
                secondaryMuscles: secondary,
                targetSets: sets,
                targetReps: reps
            )
        )
    }
}

struct LiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90

    @StateObject private var controller: SessionController
    @State private var showAddExercise = false
    @State private var restFired = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(program: Program?, programDay: ProgramDay?) {
        _controller = StateObject(
            wrappedValue: SessionController(
                program: program,
                programDay: programDay,
                defaultRest: UserDefaults.standard.object(forKey: "defaultRestSeconds") as? Int ?? 90
            )
        )
    }

    private var accent: Color {
        AccentOption(rawValue: accentName)?.color ?? .orange
    }

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                restTimerCard
                if controller.exercises.isEmpty {
                    Text("Add an exercise to start logging sets.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(16)
                        .opaqueCard()
                }
                ForEach(controller.exercises) { exercise in
                    SessionExerciseCard(
                        exercise: exercise,
                        unit: unit,
                        accent: accent,
                        onLog: { weightKg, reps, rir in
                            controller.logSet(exerciseID: exercise.id, weightKg: weightKg, reps: reps, rir: rir)
                        },
                        onDeleteSet: { setID in
                            controller.removeSet(exerciseID: exercise.id, setID: setID)
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle(controller.programDay?.name ?? "Empty workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    finish()
                } label: {
                    Text("Finish workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(controller.loggedSetCount == 0)
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showAddExercise) {
            NavigationStack {
                ExercisePickerView { catalog, sets, reps in
                    controller.addExercise(catalog, sets: sets, reps: reps)
                } onCustom: { name, primary, secondary, sets, reps in
                    controller.addCustom(name: name, primary: primary, secondary: secondary, sets: sets, reps: reps)
                }
            }
        }
        .onReceive(timer) { _ in
            let wasRunning = controller.timerRunning && controller.restRemaining > 0
            controller.tick()
            if wasRunning && controller.restRemaining == 0 {
                restFired.toggle()
            }
        }
        .sensoryFeedback(.success, trigger: restFired)
        .onAppear {
            controller.restDuration = defaultRestSeconds
            if !controller.timerRunning {
                controller.restRemaining = defaultRestSeconds
            }
        }
    }

    private var restTimerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rest timer")
                    .font(.headline)
                Spacer()
                Text(Formatters.duration(controller.restRemaining))
                    .font(.title.monospacedDigit().weight(.bold))
                    .foregroundStyle(controller.timerRunning ? accent : .primary)
            }
            Stepper(value: Binding(
                get: { controller.restDuration },
                set: { newValue in
                    controller.restDuration = newValue
                    defaultRestSeconds = newValue
                    if !controller.timerRunning {
                        controller.restRemaining = newValue
                    }
                }
            ), in: 15...300, step: 15) {
                Text("Target \(controller.restDuration)s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button("Start") { controller.startRest() }
                    .buttonStyle(.borderedProminent)
                Button("Reset") { controller.resetRest() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private func finish() {
        let session = WorkoutSession(
            startDate: controller.startedAt,
            source: controller.isEmpty ? SessionSource.empty : SessionSource.programmed,
            programUUID: controller.program?.uuid,
            programDayIndex: controller.programDay.map { day in
                controller.program?.orderedDays.firstIndex(where: { $0.uuid == day.uuid })
            } ?? nil,
            programDayName: controller.programDay?.name
        )
        session.endDate = Date()
        session.durationSeconds = max(Int(Date().timeIntervalSince(controller.startedAt)), 1)
        modelContext.insert(session)

        for exercise in controller.exercises {
            for set in exercise.logged {
                let log = SetLog(
                    exerciseName: exercise.name,
                    primaryMuscles: exercise.primaryMuscles,
                    secondaryMuscles: exercise.secondaryMuscles,
                    weight: set.weightKg,
                    reps: set.reps,
                    rir: set.rir,
                    targetReps: exercise.targetReps
                )
                log.session = session
                modelContext.insert(log)
            }
        }
        try? modelContext.save()
        dismiss()
    }
}

struct SessionExerciseCard: View {
    let exercise: DraftExercise
    let unit: WeightUnit
    let accent: Color
    var onLog: (Double, Int, Int) -> Void
    var onDeleteSet: (UUID) -> Void

    @State private var weightInput: Double = 0
    @State private var repsInput: Int = 8
    @State private var rirInput: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text("Target \(exercise.targetSets)×\(exercise.targetReps)  ·  \(exercise.primaryMuscles.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(exercise.logged.enumerated()), id: \.element.id) { index, set in
                HStack {
                    Text("Set \(index + 1)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(unit.format(set.weightKg))
                    Text("× \(set.reps)")
                    RIRBadge(rir: set.rir, accent: accent)
                    Button {
                        onDeleteSet(set.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .font(.subheadline.monospacedDigit())
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Weight (\(unit.rawValue))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $weightInput, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading) {
                        Text("Reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $repsInput, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                Text("RIR")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                RIRSelector(rir: $rirInput, accent: accent)
                Button {
                    let kg = unit.toKg(weightInput)
                    onLog(kg, max(repsInput, 1), rirInput)
                } label: {
                    Text("Log set")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }

            if exercise.targetReps > 0, let last = exercise.logged.last {
                let ratio = Double(last.reps) / Double(exercise.targetReps)
                Text("Last set \(Int((ratio * 100).rounded()))% of target reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .opaqueCard()
        .onAppear {
            if weightInput == 0, let last = exercise.logged.last {
                weightInput = unit.fromKg(last.weightKg)
                repsInput = last.reps
                rirInput = last.rir
            } else if weightInput == 0 {
                repsInput = max(exercise.targetReps, 1)
            }
        }
    }
}
