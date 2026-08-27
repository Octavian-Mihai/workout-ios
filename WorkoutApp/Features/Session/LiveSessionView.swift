import SwiftUI
import SwiftData
import Combine

struct DraftExercise: Identifiable {
    let id: UUID
    var name: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var logged: [DraftSet]

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        logged: [DraftSet] = []
    ) {
        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
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

enum SessionField: Hashable {
    case weight(UUID)
    case reps(UUID)
}

@MainActor
final class SessionController: ObservableObject {
    @Published var exercises: [DraftExercise]
    @Published var restDuration: Int
    @Published var restRemaining: Int
    @Published var timerRunning = false
    @Published var restCompletedPulse = 0
    @Published var startedAt: Date

    let program: Program?
    let programDay: ProgramDay?
    let isEmpty: Bool
    let originalNames: [String]

    private var timerCancellable: AnyCancellable?

    init(program: Program?, programDay: ProgramDay?, defaultRest: Int = 90) {
        self.program = program
        self.programDay = programDay
        self.isEmpty = programDay == nil
        self.restDuration = defaultRest
        self.restRemaining = defaultRest
        self.startedAt = Date()
        if let day = programDay {
            let ordered = day.orderedExercises
            self.originalNames = ordered.map(\.name)
            self.exercises = ordered.map { item in
                DraftExercise(
                    name: item.name,
                    primaryMuscles: item.primaryMuscles,
                    secondaryMuscles: item.secondaryMuscles
                )
            }
        } else {
            self.originalNames = []
            self.exercises = []
        }
    }

    var loggedSetCount: Int {
        exercises.reduce(0) { $0 + $1.logged.count }
    }

    var exerciseListChanged: Bool {
        guard !isEmpty else { return false }
        return exercises.map(\.name) != originalNames
    }

    func tick() {
        guard timerRunning, restRemaining > 0 else { return }
        restRemaining -= 1
        if restRemaining == 0 {
            timerRunning = false
            restCompletedPulse += 1
            stopTimer()
        }
    }

    func startRest() {
        restRemaining = restDuration
        timerRunning = true
        ensureTimer()
    }

    func resetRest() {
        restRemaining = restDuration
        timerRunning = false
        stopTimer()
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func ensureTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
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

    func addExercise(_ catalog: CatalogExercise) {
        exercises.append(
            DraftExercise(
                name: catalog.name,
                primaryMuscles: catalog.primaryNames,
                secondaryMuscles: catalog.secondaryNames
            )
        )
    }

    func addCustom(name: String, primary: [String], secondary: [String]) {
        exercises.append(
            DraftExercise(
                name: name,
                primaryMuscles: primary,
                secondaryMuscles: secondary
            )
        )
    }
}

struct LiveSessionView: View {
    @ObservedObject var controller: SessionController
    var onMinimize: () -> Void
    var onFinished: () -> Void
    var onDiscard: () -> Void

    @Environment(\.modelContext) private var modelContext
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90
    @AppStorage("restTimerHaptics") private var restTimerHaptics = true

    @State private var showAddExercise = false
    @State private var showSaveTemplate = false
    @State private var showDiscardConfirm = false
    @FocusState private var focusedField: SessionField?

    private var accent: Color {
        AccentOption(rawValue: accentName)?.color ?? .orange
    }

    private var unit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        VStack(spacing: 0) {
            compactRestTimer
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if controller.exercises.isEmpty {
                        Text("Add an exercise to start logging sets.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .opaqueCard()
                    }
                    ForEach(controller.exercises) { exercise in
                        SessionExerciseCard(
                            exercise: exercise,
                            unit: unit,
                            accent: accent,
                            focusedField: $focusedField,
                            onLog: { weightKg, reps, rir in
                                controller.logSet(exerciseID: exercise.id, weightKg: weightKg, reps: reps, rir: rir)
                            },
                            onDeleteSet: { setID in
                                controller.removeSet(exerciseID: exercise.id, setID: setID)
                            }
                        )
                    }

                    Button {
                        finish()
                    } label: {
                        Text("Finish workout")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .disabled(controller.loggedSetCount == 0)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)

                    Button("Discard workout", role: .destructive) {
                        if controller.loggedSetCount > 0 {
                            showDiscardConfirm = true
                        } else {
                            onDiscard()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle(controller.programDay?.name ?? "Empty workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { onMinimize() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .sheet(isPresented: $showAddExercise) {
            NavigationStack {
                ExercisePickerView { catalog in
                    controller.addExercise(catalog)
                } onCustom: { name, primary, secondary in
                    controller.addCustom(name: name, primary: primary, secondary: secondary)
                }
            }
        }
        .alert("Save this day as a template?", isPresented: $showSaveTemplate) {
            Button("Save template") {
                rewriteDayTemplate()
                onFinished()
            }
            Button("Don’t save", role: .cancel) {
                onFinished()
            }
        } message: {
            Text("Exercises were added, removed, or reordered. Save them to this program day, or keep the original template.")
        }
        .alert("Discard this workout?", isPresented: $showDiscardConfirm) {
            Button("Discard", role: .destructive) { onDiscard() }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Logged sets will be lost.")
        }
        .sensoryFeedback(.success, trigger: restTimerHaptics ? controller.restCompletedPulse : 0)
    }

    private var compactRestTimer: some View {
        HStack(spacing: 10) {
            Text(Formatters.duration(controller.restRemaining))
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(controller.timerRunning ? accent : .primary)
                .frame(minWidth: 64, alignment: .leading)
            Text("Rest")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Stepper(
                value: Binding(
                    get: { controller.restDuration },
                    set: { newValue in
                        controller.restDuration = newValue
                        defaultRestSeconds = newValue
                        if !controller.timerRunning {
                            controller.restRemaining = newValue
                        }
                    }
                ),
                in: 15...300,
                step: 15
            ) {
                Text("\(controller.restDuration)s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .labelsHidden()
            .frame(width: 92)
            Button(controller.timerRunning ? "Reset" : "Start") {
                if controller.timerRunning {
                    controller.resetRest()
                } else {
                    controller.startRest()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.cardFill)
        .overlay(alignment: .bottom) {
            Divider()
        }
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
                    targetReps: nil
                )
                log.session = session
                modelContext.insert(log)
            }
        }
        try? modelContext.save()

        if controller.exerciseListChanged {
            showSaveTemplate = true
        } else {
            onFinished()
        }
    }

    private func rewriteDayTemplate() {
        guard let day = controller.programDay else { return }
        for existing in day.exercises {
            modelContext.delete(existing)
        }
        for (index, exercise) in controller.exercises.enumerated() {
            let item = DayExercise(
                name: exercise.name,
                primaryMuscles: exercise.primaryMuscles,
                secondaryMuscles: exercise.secondaryMuscles,
                targetSets: 0,
                targetReps: 0,
                sortIndex: index
            )
            item.day = day
            modelContext.insert(item)
        }
        try? modelContext.save()
    }
}

struct SessionExerciseCard: View {
    let exercise: DraftExercise
    let unit: WeightUnit
    let accent: Color
    var focusedField: FocusState<SessionField?>.Binding
    var onLog: (Double, Int, Int) -> Void
    var onDeleteSet: (UUID) -> Void

    @State private var weightInput: Double = 0
    @State private var repsInput: Int = 8
    @State private var rirInput: Int = 3

    private var isInputFocused: Bool {
        switch focusedField.wrappedValue {
        case .weight(let id), .reps(let id):
            return id == exercise.id
        default:
            return false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                if !exercise.primaryMuscles.isEmpty {
                    Text(exercise.primaryMuscles.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                            .focused(focusedField, equals: .weight(exercise.id))
                    }
                    VStack(alignment: .leading) {
                        Text("Reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $repsInput, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .focused(focusedField, equals: .reps(exercise.id))
                    }
                }
                if isInputFocused {
                    Text("RIR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    RIRSelector(rir: $rirInput, accent: accent)
                }
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
        }
        .padding(16)
        .opaqueCard()
        .onAppear {
            if weightInput == 0, let last = exercise.logged.last {
                weightInput = unit.fromKg(last.weightKg)
                repsInput = last.reps
                rirInput = last.rir
            }
        }
    }
}
