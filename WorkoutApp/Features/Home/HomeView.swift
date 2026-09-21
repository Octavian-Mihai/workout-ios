import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Program.createdAt) private var programs: [Program]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @EnvironmentObject private var sessionStore: ActiveSessionStore
    @EnvironmentObject private var health: HealthKitService
    @Environment(AppTheme.self) private var theme
    @AppStorage(RunningVisibility.showActivityKey) private var showRunningActivity = true
    @AppStorage(StressVisibility.showAnalysisKey) private var showStressAnalysis = true

    @Environment(AppTourController.self) private var tour
    @State private var showTrends = false

    private var nextDay: ProgramDay? {
        NextWorkoutResolver.nextDay(activeProgram: programs.first(where: \.isActive), sessions: sessions)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        YearActivityGrid(
                            sessions: sessions,
                            runDates: showRunningActivity ? health.activityRunDays : [],
                            showsRunningActivity: showRunningActivity
                        ) { _ in
                            showTrends = true
                        }
                        .tourTarget(.homeYearGrid)
                        .id(AppTourTargetID.homeYearGrid)

                        if showStressAnalysis {
                            MuscleFreshnessCompactCard(sessions: sessions)
                                .tourTarget(.homeTodayStress)
                                .id(AppTourTargetID.homeTodayStress)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            if let program = programs.first(where: \.isActive), let day = nextDay {
                                NextWorkoutCard(program: program, day: day) {
                                    sessionStore.start(program: program, programDay: day)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No active program")
                                        .font(.headline)
                                    Text("Create a program from a starter template on the Workout tab and mark it active. You can still start an empty workout.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .opaqueCard()
                            }

                            HStack(spacing: 10) {
                                Button {
                                    if let last = sessions.first(where: { $0.endDate != nil }) {
                                        sessionStore.start(from: last)
                                    }
                                } label: {
                                    Label("Repeat last workout", systemImage: "arrow.counterclockwise")
                                        .homeActionButtonLabel()
                                }
                                .buttonStyle(.bordered)
                                .disabled(sessions.first(where: { $0.endDate != nil }) == nil)
                                .frame(maxWidth: .infinity)

                                Button {
                                    sessionStore.start(program: nil, programDay: nil)
                                } label: {
                                    Label("Start empty workout", systemImage: "plus.circle.fill")
                                        .homeActionButtonLabel()
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .tourTarget(.homeStartWorkout)
                        .id(AppTourTargetID.homeStartWorkout)
                    }
                    .padding(16)
                }
                .onAppear {
                    if tour.isActive {
                        scrollHomeTour(tour.step, proxy: proxy)
                    }
                }
                .onChange(of: tour.isActive) { _, active in
                    if active {
                        scrollHomeTour(tour.step, proxy: proxy)
                    }
                }
                .onChange(of: tour.step) { _, step in
                    scrollHomeTour(step, proxy: proxy)
                }
            }
            .background(theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showTrends) {
                TrendsDetailView()
            }
        }
    }

    private func scrollHomeTour(_ step: AppTourStep, proxy: ScrollViewProxy) {
        let id: AppTourTargetID?
        switch step {
        case .homeYearGrid: id = .homeYearGrid
        case .homeTodayStress: id = .homeTodayStress
        case .homeStartWorkout: id = .homeStartWorkout
        default: id = nil
        }
        guard let id else { return }
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(id, anchor: .center)
            }
            tour.requestFrameRefresh()
        }
    }
}

struct NextWorkoutCard: View {
    let program: Program
    let day: ProgramDay
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 4) {
                HStack {
                    Text("Next workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text(program.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(day.name)
                        .font(.title2.weight(.bold))
                    Spacer(minLength: 8)
                    if let estimate = durationLabel {
                        Text(estimate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            if previewExercises.isEmpty {
                Text("No exercises yet — add some in the program editor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8, alignment: .topLeading),
                        GridItem(.flexible(), spacing: 8, alignment: .topLeading)
                    ],
                    alignment: .leading,
                    spacing: 6
                ) {
                    ForEach(previewExercises) { exercise in
                        Text(exercise.name)
                            .font(.subheadline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if day.orderedExercises.count > 6 {
                    Text("+\(day.orderedExercises.count - 6) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: onStart) {
                Text("Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .opaqueCard()
    }

    private var previewExercises: [DayExercise] {
        Array(day.orderedExercises.prefix(6))
    }

    private var durationLabel: String? {
        let exercises = day.orderedExercises
        return WorkoutDurationEstimate.label(
            exerciseCount: exercises.count,
            totalSets: exercises.reduce(0) { $0 + max($1.targetSets, 0) }
        )
    }
}

private struct HomeActionLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 6) {
            configuration.icon
                .font(.subheadline.weight(.semibold))
                .imageScale(.medium)
                .frame(width: 18, height: 18, alignment: .center)
            configuration.title
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }
}

private extension View {
    func homeActionButtonLabel() -> some View {
        labelStyle(HomeActionLabelStyle())
    }
}
