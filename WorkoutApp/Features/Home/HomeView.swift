import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Program.createdAt) private var programs: [Program]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @EnvironmentObject private var sessionStore: ActiveSessionStore
    @EnvironmentObject private var health: HealthKitService
    @Environment(AppTheme.self) private var theme
    @AppStorage(RunningVisibility.showActivityKey) private var showRunningActivity = true

    @Environment(AppTourController.self) private var tour
    @State private var showTrends = false

    private var accent: Color {
        theme.accent
    }

    private var nextDay: ProgramDay? {
        NextWorkoutResolver.nextDay(activeProgram: programs.first(where: \.isActive), sessions: sessions)
    }

    private var allSets: [SetLog] {
        sessions.flatMap(\.sets)
    }

    private var stressCardio: [CardioWorkout] {
        showRunningActivity
            ? health.cardioWorkouts
            : health.cardioWorkouts.filter { $0.activityType != .running }
    }

    private var todayStress: StressEstimate {
        StressCalculator.todayEstimate(
            sets: allSets,
            cardioWorkouts: stressCardio,
            restingHeartRate: health.restingHeartRate,
            maxHeartRate: health.maxHeartRate
        )
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

                        TodayStressCard(estimate: todayStress, accent: accent, compact: true)
                            .tourTarget(.homeTodayStress)
                            .id(AppTourTargetID.homeTodayStress)

                        VStack(alignment: .leading, spacing: 16) {
                            if let program = programs.first(where: \.isActive), let day = nextDay {
                                NextWorkoutCard(program: program, day: day) {
                                    sessionStore.start(program: program, programDay: day)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No active program")
                                        .font(.headline)
                                    Text("Create a program on the Workout tab and mark it active. You can still start an empty workout.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .opaqueCard()
                            }

                            Button {
                                sessionStore.start(program: nil, programDay: nil)
                            } label: {
                                Label("Start empty workout", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(day.name)
                        .font(.title2.weight(.bold))
                    Text(program.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if day.orderedExercises.isEmpty {
                Text("No exercises yet — add some in the program editor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(day.orderedExercises.prefix(6)) { exercise in
                        Text(exercise.name)
                            .font(.subheadline)
                    }
                    if day.orderedExercises.count > 6 {
                        Text("+\(day.orderedExercises.count - 6) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
}
