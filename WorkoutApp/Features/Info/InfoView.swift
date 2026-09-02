import SwiftUI
import SwiftData

enum InfoPageVisibility {
    static let showTodayStressKey = "infoShowTodayStress"
    static let showTonnageKey = "infoShowTonnage"
    static let showVolumeChartsKey = "infoShowVolumeCharts"
    static let showEstimated1RMKey = "infoShowEstimated1RM"
    static let showIntensityMapKey = "infoShowIntensityMap"
}

struct InfoView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @EnvironmentObject private var health: HealthKitService
    @Environment(AppTheme.self) private var theme
    @AppStorage(InfoPageVisibility.showTodayStressKey) private var showTodayStress = true
    @AppStorage(InfoPageVisibility.showTonnageKey) private var showTonnage = true
    @AppStorage(InfoPageVisibility.showVolumeChartsKey) private var showVolumeCharts = true
    @AppStorage(InfoPageVisibility.showEstimated1RMKey) private var showEstimated1RM = true
    @AppStorage(InfoPageVisibility.showIntensityMapKey) private var showIntensityMap = true
    @State private var stressExpanded = true
    @State private var analyticsExpanded = false

    private var accent: Color {
        theme.accent
    }

    private var allSets: [SetLog] {
        sessions.flatMap(\.sets)
    }

    private var showsAnalytics: Bool {
        showTonnage || showVolumeCharts || showEstimated1RM || showIntensityMap
    }

    private var estimate: StressEstimate {
        StressCalculator.todayEstimate(
            sets: allSets,
            cardioWorkouts: health.cardioWorkouts,
            restingHeartRate: health.restingHeartRate,
            maxHeartRate: health.maxHeartRate
        )
    }

    private var trend: [DailyStress] {
        StressCalculator.dailyTrend(
            sets: allSets,
            cardioWorkouts: health.cardioWorkouts,
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
                    if showTodayStress {
                        DisclosureGroup(isExpanded: $stressExpanded) {
                            VStack(alignment: .leading, spacing: 16) {
                                TodayStressCard(
                                    estimate: estimate,
                                    showSplit: true,
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
                .padding(16)
            }
            .background(theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Info")
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
}

struct LearnLinksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learn")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            learnLink("Core movement categories", destination: CoreMovementCategoriesView())
            learnLink("Key muscle groups", destination: KeyMuscleGroupsView())
            learnLink("More strength patterns", destination: MoreStrengthPatternsView())
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
