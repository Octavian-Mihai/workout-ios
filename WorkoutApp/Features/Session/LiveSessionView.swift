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

    var exerciseID: UUID {
        switch self {
        case .weight(let id), .reps(let id):
            return id
        }
    }

    var isWeight: Bool {
        if case .weight = self { return true }
        return false
    }
}

struct ExerciseDraft: Equatable {
    var weightText: String = ""
    var repsText: String = "8"
    var rir: Int = 3
    var didSeed = false
}

@MainActor
final class SessionController: ObservableObject {
    @Published var exercises: [DraftExercise]
    @Published var restDuration: Int
    @Published var restRemaining: Int
    @Published var timerRunning = false
    @Published var restCompletedPulse = 0
    @Published var startedAt: Date
    @Published var focusedField: SessionField?
    @Published var drafts: [UUID: ExerciseDraft] = [:]

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
        self.focusedField = nil
        if let day = programDay {
            let ordered = day.orderedExercises
            self.originalNames = ordered.map(\.name)
            let list = ordered.map { item in
                DraftExercise(
                    name: item.name,
                    primaryMuscles: item.primaryMuscles,
                    secondaryMuscles: item.secondaryMuscles
                )
            }
            self.exercises = list
            self.drafts = Dictionary(uniqueKeysWithValues: list.map { ($0.id, ExerciseDraft()) })
        } else {
            self.originalNames = []
            self.exercises = []
            self.drafts = [:]
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
        let exercise = DraftExercise(
            name: catalog.name,
            primaryMuscles: catalog.primaryNames,
            secondaryMuscles: catalog.secondaryNames
        )
        exercises.append(exercise)
        drafts[exercise.id] = ExerciseDraft()
    }

    func addCustom(name: String, primary: [String], secondary: [String]) {
        let exercise = DraftExercise(
            name: name,
            primaryMuscles: primary,
            secondaryMuscles: secondary
        )
        exercises.append(exercise)
        drafts[exercise.id] = ExerciseDraft()
    }

    func draft(for id: UUID) -> ExerciseDraft {
        drafts[id] ?? ExerciseDraft()
    }

    func updateDraft(for id: UUID, _ body: (inout ExerciseDraft) -> Void) {
        var value = drafts[id] ?? ExerciseDraft()
        body(&value)
        drafts[id] = value
    }
}

struct LiveSessionView: View {
    @ObservedObject var controller: SessionController
    var onMinimize: () -> Void
    var onFinished: () -> Void
    var onDiscard: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var pastSessions: [WorkoutSession]
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90
    @AppStorage("restTimerHaptics") private var restTimerHaptics = true

    @State private var showAddExercise = false
    @State private var showSaveTemplate = false
    @State private var showDiscardConfirm = false

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
                            controller: controller,
                            exercise: exercise,
                            unit: unit,
                            accent: accent,
                            previousSets: previousSets(for: exercise.name),
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
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            sessionKeyboard
        }
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
        }
        .onDisappear {
            controller.focusedField = nil
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
        .onChange(of: controller.restCompletedPulse) { _, pulse in
            if pulse > 0 {
                RestTimerSound.play()
            }
        }
    }

    @ViewBuilder
    private var sessionKeyboard: some View {
        if let field = controller.focusedField {
            let id = field.exerciseID
            let exerciseName = controller.exercises.first(where: { $0.id == id })?.name ?? ""
            SessionInputKeyboard(
                mode: field.isWeight ? .weight : .reps,
                accent: accent,
                unit: unit,
                equipment: ExerciseCatalog.equipment(forName: exerciseName),
                weightText: Binding(
                    get: { controller.draft(for: id).weightText },
                    set: { newValue in controller.updateDraft(for: id) { $0.weightText = newValue } }
                ),
                repsText: Binding(
                    get: { controller.draft(for: id).repsText },
                    set: { newValue in controller.updateDraft(for: id) { $0.repsText = newValue } }
                ),
                rir: Binding(
                    get: { controller.draft(for: id).rir },
                    set: { newValue in controller.updateDraft(for: id) { $0.rir = newValue } }
                ),
                onDismiss: { controller.focusedField = nil },
                onNext: { controller.focusedField = .reps(id) },
                onCompleteSet: { completeSet(exerciseID: id) }
            )
        }
    }

    private func completeSet(exerciseID: UUID) {
        let draft = controller.draft(for: exerciseID)
        let weight = Double(draft.weightText) ?? 0
        let reps = Int(draft.repsText) ?? 0
        controller.logSet(
            exerciseID: exerciseID,
            weightKg: unit.toKg(weight),
            reps: max(reps, 1),
            rir: draft.rir
        )
        controller.focusedField = nil
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

    private func previousSets(for name: String) -> [SetLog] {
        for session in pastSessions where session.endDate != nil {
            let sets = session.orderedSets.filter {
                $0.exerciseName.compare(name, options: .caseInsensitive) == .orderedSame
            }
            if !sets.isEmpty { return sets }
        }
        return []
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
    @ObservedObject var controller: SessionController
    let exercise: DraftExercise
    let unit: WeightUnit
    let accent: Color
    let previousSets: [SetLog]
    var onDeleteSet: (UUID) -> Void

    private var live: DraftExercise {
        controller.exercises.first(where: { $0.id == exercise.id }) ?? exercise
    }

    private var draft: ExerciseDraft {
        controller.draft(for: exercise.id)
    }

    private var weightFocused: Bool {
        controller.focusedField == .weight(exercise.id)
    }

    private var repsFocused: Bool {
        controller.focusedField == .reps(exercise.id)
    }

    private var previousLine: String? {
        guard !previousSets.isEmpty else { return nil }
        let sets = previousSets.map { set in
            "\(unit.formatNumber(set.weight)) / \(set.reps) RIR \(RIRPalette.display(set.rir))"
        }.joined(separator: "  ·  ")
        return "Last  \(sets)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(live.name)
                    .font(.headline)
                if !live.primaryMuscles.isEmpty {
                    Text(live.primaryMuscles.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let previousLine {
                    Text(previousLine)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            if !live.logged.isEmpty {
                List {
                    ForEach(Array(live.logged.enumerated()), id: \.element.id) { index, set in
                        loggedRow(index: index, set: set)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    onDeleteSet(set.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .frame(height: CGFloat(live.logged.count) * 44)
            }

            HStack(spacing: 10) {
                inputField(
                    title: "Weight (\(unit.rawValue))",
                    value: draft.weightText.isEmpty ? "0" : draft.weightText,
                    focused: weightFocused
                ) {
                    controller.focusedField = .weight(exercise.id)
                }
                inputField(
                    title: "Reps",
                    value: draft.repsText.isEmpty ? "0" : draft.repsText,
                    focused: repsFocused
                ) {
                    controller.focusedField = .reps(exercise.id)
                }
            }
        }
        .padding(16)
        .opaqueCard()
        .onAppear(perform: seedDraftIfNeeded)
    }

    private func inputField(title: String, value: String, focused: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                    .padding(.horizontal, 10)
                    .background(Theme.mutedFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(focused ? accent : Color.clear, lineWidth: 2)
                    )
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private func loggedRow(index: Int, set: DraftSet) -> some View {
        HStack {
            Text("Set \(index + 1)")
                .foregroundStyle(.secondary)
            Spacer()
            Text(unit.format(set.weightKg))
            Text("× \(set.reps)")
            RIRBadge(rir: set.rir, accent: accent)
        }
        .font(.subheadline.monospacedDigit())
    }

    private func seedDraftIfNeeded() {
        var current = controller.draft(for: exercise.id)
        guard !current.didSeed else { return }
        if let last = live.logged.last {
            current.weightText = unit.formatNumber(last.weightKg)
            current.repsText = "\(last.reps)"
            current.rir = last.rir
        } else if let last = previousSets.last {
            current.weightText = unit.formatNumber(last.weight)
            current.repsText = "\(last.reps)"
            current.rir = last.rir
        }
        current.didSeed = true
        controller.drafts[exercise.id] = current
    }
}
