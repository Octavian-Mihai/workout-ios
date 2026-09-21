import SwiftUI
import SwiftData

enum InfoPageVisibility {
    static let showTodayStressKey = "infoShowTodayStress"
    static let showTonnageKey = "infoShowTonnage"
    static let showVolumeChartsKey = "infoShowVolumeCharts"
    static let showEstimated1RMKey = "infoShowEstimated1RM"
    static let showIntensityMapKey = "infoShowIntensityMap"
    static let showTrainingLoadEvolutionKey = "infoShowTrainingLoadEvolution"
    static let stressExpandedKey = "infoStressExpanded"
    static let analyticsExpandedKey = "infoAnalyticsExpanded"
}

enum RunningVisibility {
    static let showTabKey = "showRunningTab"
    static let showActivityKey = "showRunningActivity"
    static let olderExpandedKey = "runningOlderExpanded"
}

enum StressVisibility {
    static let showAnalysisKey = InfoPageVisibility.showTodayStressKey
}

struct InfoView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @EnvironmentObject private var health: HealthKitService
    @Environment(AppTheme.self) private var theme
    @AppStorage(StressVisibility.showAnalysisKey) private var showStressAnalysis = true
    @AppStorage(InfoPageVisibility.showTonnageKey) private var showTonnage = true
    @AppStorage(InfoPageVisibility.showVolumeChartsKey) private var showVolumeCharts = true
    @AppStorage(InfoPageVisibility.showEstimated1RMKey) private var showEstimated1RM = true
    @AppStorage(InfoPageVisibility.showIntensityMapKey) private var showIntensityMap = true
    @AppStorage(InfoPageVisibility.showTrainingLoadEvolutionKey) private var showTrainingLoadEvolution = true
    @AppStorage(RunningVisibility.showActivityKey) private var showRunningActivity = true
    @Environment(AppTourController.self) private var tour
    @AppStorage(InfoPageVisibility.stressExpandedKey) private var stressExpanded = true
    @AppStorage(InfoPageVisibility.analyticsExpandedKey) private var analyticsExpanded = false

    private var accent: Color {
        theme.accent
    }

    private var allSets: [SetLog] {
        sessions.flatMap(\.sets)
    }

    private var showsAnalytics: Bool {
        showTonnage || showVolumeCharts || showEstimated1RM || showIntensityMap || showTrainingLoadEvolution
    }

    private var stressCardio: [CardioWorkout] {
        showRunningActivity
            ? health.cardioWorkouts
            : health.cardioWorkouts.filter { $0.activityType != .running }
    }

    private var estimate: StressEstimate {
        StressCalculator.todayEstimate(
            sets: allSets,
            cardioWorkouts: stressCardio,
            restingHeartRate: health.restingHeartRate,
            maxHeartRate: health.maxHeartRate
        )
    }

    private var trend: [DailyStress] {
        StressCalculator.dailyTrend(
            sets: allSets,
            cardioWorkouts: stressCardio,
            restingHeartRate: health.restingHeartRate,
            maxHeartRate: health.maxHeartRate
        )
    }

    private var recoveryContext: String? {
        StressCalculator.recoveryContextLabel(
            hrvSDNN: health.hrvSDNN,
            sleepHours: health.lastNightSleepHours
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if showStressAnalysis {
                        DisclosureGroup(isExpanded: $stressExpanded) {
                            VStack(alignment: .leading, spacing: 16) {
                                TodayStressCard(
                                    estimate: estimate,
                                    showSplit: true,
                                    showRunSplit: showRunningActivity,
                                    trend: trend,
                                    accent: accent
                                )

                                if health.cardioWorkouts.contains(where: { $0.activityType != .running }) {
                                    Text("Cardio stress includes walking, hiking, and cycling from Apple Health.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let recoveryContext {
                                    Text(recoveryContext)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                NavigationLink {
                                    MuscleFreshnessView()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Muscle freshness")
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text("Per-muscle recovery from recent training")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(16)
                                    .opaqueCard()
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 8)
                        } label: {
                            Text("My stress")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        .tint(.secondary)
                    }

                    exerciseHistoryLink

                    measurementsLink

                    if showsAnalytics {
                        DisclosureGroup(isExpanded: $analyticsExpanded) {
                            StrengthAnalyticsView(sets: allSets, accent: accent)
                                .padding(.top, 8)
                        } label: {
                            Text("Analytics")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        .tint(.secondary)
                    }
                }
                .tourTarget(.infoAnalytics)
                .padding(16)
                .onChange(of: tour.step) { _, step in
                    if step == .infoAnalytics {
                        stressExpanded = true
                    }
                }
            }
            .background(theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var exerciseHistoryLink: some View {
        NavigationLink {
            ExerciseHistoryBrowserView(accent: accent)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise history")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("1RM and weight evolution for logged lifts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .opaqueCard()
        }
        .buttonStyle(.plain)
    }

    private var measurementsLink: some View {
        NavigationLink {
            MeasurementsView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Measurements")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Progress photos, body weight, calories, and circumferences")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .opaqueCard()
        }
        .buttonStyle(.plain)
    }
}

struct LearnLinksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            learnLink("Using the app", destination: AppUsageGuideView())
            learnLink("Core movement categories", destination: CoreMovementCategoriesView())
            learnLink("Key muscle groups", destination: KeyMuscleGroupsView())
            learnLink("Strength patterns", destination: MoreStrengthPatternsView())
        }
    }

    private func learnLink<D: View>(_ title: String, destination: D) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(16)
            .opaqueCard()
        }
        .buttonStyle(.plain)
    }
}

struct ArticleScreen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(AppTheme.self) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
        }
        .background(theme.groupedBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ArticleCard: View {
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(bodyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .opaqueCard()
    }
}

struct AppUsageGuideView: View {
    var body: some View {
        ArticleScreen(title: "Using the app") {
            ArticleCard(
                title: "What this covers",
                bodyText: "How the app works — logging, sharing, history, and settings. For movement patterns and muscle notes, open the other Learn links on the Workout tab."
            )
            ArticleCard(
                title: "Stress analysis",
                bodyText: "Settings → Stress controls whether stress scores appear on Home, Info, Running, and widgets. Turn it off if you want a cleaner view without losing your logged workouts."
            )
            ArticleCard(
                title: "Plate calculator",
                bodyText: "During a session, barbell exercises show plates per side above the weight keypad. Set your default bar weight in Settings → Equipment. Machine and functional-trainer lifts use the logged weight directly — no bar subtracted. On barbell lifts, use the +/− next to Bar to adjust for a lighter or specialty bar during that session only."
            )
            ArticleCard(
                title: "Share your workout",
                bodyText: "When you finish a session, the summary screen shows sets, top lifts with unit labels, and exercise photos. Tap Share to send a PNG card — handy for a training log or social post."
            )
            ArticleCard(
                title: "Workout history",
                bodyText: "Workout → History lists finished sessions with duration, set count, and volume in your chosen unit (lbs or kg). Open a session for the full set log. Swipe left or tap Delete to remove a workout. Sessions older than two weeks tuck into a separate folder."
            )
            ArticleCard(
                title: "Custom exercises",
                bodyText: "Workout → Custom exercises lists every exercise you created. Share one or all to the developer for catalog review, or delete exercises you no longer need — that removes them from programs and logged sets."
            )
            ArticleCard(
                title: "Programs & templates",
                bodyText: "Workout → Programs: create from a starter template, import a JSON plan, or build a blank program with rotating days. Mark one program active so Home knows what comes next."
            )
            ArticleCard(
                title: "Expandable sections",
                bodyText: "Programs, Learn, Custom exercises, History, and Info analytics remember whether you left them open or closed."
            )
        }
    }
}

struct RIRGuideView: View {
    var body: some View {
        ArticleScreen(title: "RIR") {
            ArticleCard(
                title: "What RIR is",
                bodyText: "RIR means reps in reserve — how many more clean reps you could have done. A set of 8 at RIR 2 means you had about two reps left. Log the set you actually did, then mark RIR honestly."
            )
            ArticleCard(
                title: "0–1 grind",
                bodyText: "Near failure. Useful for testing a top set, but these cost a lot of fatigue. Keep them scarce if you train often."
            )
            ArticleCard(
                title: "2–3 productive",
                bodyText: "Hard, useful work. Most working sets belong here: challenging enough to drive progress, with a little room left so form stays solid."
            )
            ArticleCard(
                title: "4 easy",
                bodyText: "Comfortable sets. Good for warm-ups, back-off work, or days you are managing fatigue instead of pushing."
            )
            ArticleCard(
                title: "5+ technique",
                bodyText: "Easy leftover reps. Use these for skill work, first warm-up plates, or when the load is just there to groove the pattern."
            )
            ArticleCard(
                title: "Why honest RIR matters",
                bodyText: "RIR is how the app reads how hard a set really was — not just the weight and reps. Low RIR raises fatigue and stress estimates. If you sandbag the number, trends look easier than the work you did. If you always log 0, everything looks like a grind. Match the color to how the set felt so volume, stress, and estimated 1RM stay trustworthy."
            )
        }
    }
}
