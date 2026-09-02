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
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                articleLink("Workout 101", destination: Workout101View())
                articleLink("Movements 101", destination: Movements101View())
                articleLink("Anatomy 101", destination: Anatomy101View())
                articleLink("Training insight", destination: TrainingInsightView())
                articleLink("Your Guide View", destination: YourGuideView())
            }
            .padding(.top, 8)
        } label: {
            Text("Learn")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
        }
        .tint(.secondary)
    }

    private func articleLink<D: View>(_ title: String, destination: D) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
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

struct Workout101View: View {
    var body: some View {
        ArticleScreen(title: "Workout 101") {
            ArticleCard(
                title: "What a session is",
                bodyText: "A workout is a collection of sets. Each set records weight, reps, and RIR (reps in reserve). Duration is saved when you finish. Programmed sessions follow a day in your active rotation; empty sessions are free-form and do not move that rotation."
            )
            ArticleCard(
                title: "Programs you build",
                bodyText: "This app does not ship a starter split. Create a program, add days in the order you want to repeat them, and mark one program active. After you finish a programmed day, the next workout is the next day in that list, wrapping around at the end."
            )
            ArticleCard(
                title: "Logging well",
                bodyText: "Use the rest timer between sets. Log the load and reps you actually did, then mark RIR honestly. Productive work usually lives around RIR 2–3. RIR 0–1 is a grind; RIR 4+ is easy technique or warm-up work."
            )
            ArticleCard(
                title: "Empty workouts",
                bodyText: "Use an empty workout for extras, make-up work, or days off-template. Because they are not tied to a program day, they never advance “next workout.”"
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

struct Movements101View: View {
    var body: some View {
        ArticleScreen(title: "Movements 101") {
            Text("Catalog lifts used in the program builder. Muscle tags feed volume charts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(ExerciseCatalog.grouped(), id: \.0) { category, items in
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.rawValue)
                        .font(.headline)
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                            Text("Primary: \(item.primaryNames.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !item.secondaryNames.isEmpty {
                                Text("Secondary: \(item.secondaryNames.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.cues)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(16)
                .opaqueCard()
            }
        }
    }
}

struct Anatomy101View: View {
    var body: some View {
        ArticleScreen(title: "Anatomy 101") {
            ArticleCard(
                title: "How volume is split",
                bodyText: "Each set contributes weight × reps. Primary muscles receive the full amount. Secondary muscles receive half. That is why a row loads lats and upper back more than biceps."
            )
            ForEach(Dictionary(grouping: MuscleGroup.allCases, by: \.region).sorted(by: { $0.key < $1.key }), id: \.key) { region, muscles in
                VStack(alignment: .leading, spacing: 8) {
                    Text(region)
                        .font(.headline)
                    ForEach(muscles) { muscle in
                        Text(muscle.rawValue)
                            .font(.subheadline)
                    }
                    Text(blurb(for: region))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .opaqueCard()
            }
        }
    }

    private func blurb(for region: String) -> String {
        switch region {
        case "Upper body":
            return "Chest, back, and delts are the big movers on press and pull days. Keep rear delts and upper back in the mix so pressing stays healthy."
        case "Arms":
            return "Biceps and triceps get direct work and a lot of indirect work from rows, pulldowns, presses, and dips."
        case "Lower body":
            return "Quads dominate squats and lunges; hamstrings and glutes dominate hinges. Calves and adductors show up when you train them or when stance is wide."
        default:
            return "Core and lower back stabilize almost every compound. They appear as secondary volume on squats, deadlifts, and loaded carries of attention."
        }
    }
}

struct TrainingInsightView: View {
    var body: some View {
        ArticleScreen(title: "Training insight") {
            ArticleCard(
                title: "RIR colors",
                bodyText: "0–1 red: near failure, high fatigue. 2–3 yellow-orange: hard, useful work. 4 green: productive easier sets. 5+ blue: easy, technique, or leftover reps."
            )
            ArticleCard(
                title: "Estimated 1RM",
                bodyText: "The app uses a modified Epley: weight × (1 + (reps + RIR) / 30). RIR is treated as extra unused reps, so a 100 kg × 5 at RIR 2 estimates like a 7-rep set."
            )
            ArticleCard(
                title: "Stress scores (0–100)",
                bodyText: "Central stress looks at heavy compounds, percent of estimated 1RM, and low RIR over 7 days. Total stress adds weekly volume, average intensity, and cardio stress from Health (running, walking, hiking, cycling). Both share the same scale."
            )
            ArticleCard(
                title: "Cardio stress",
                bodyText: "Run stress uses personalized TRIMP when heart rate is available — your resting HR from Health and an age-based max HR. Elevation gain adds up to +35% for hilly routes. Activity weights: running 1.0, hiking 0.85, cycling 0.75, walking 0.50."
            )
            ArticleCard(
                title: "Recovery modifier",
                bodyText: "Recovery adjusts for last night’s sleep and recent HRV from Apple Health. Sleep under 5h: −10; 5–6h: −5; 7–9h: neutral; over 9h: +5. HRV below 30ms: −5; above 50ms: +5. The modifier is clamped to [−15, +10] and added to the base recovery score."
            )
            StressLegendView()
                .padding(16)
                .opaqueCard()
            ArticleCard(
                title: "Rotation",
                bodyText: "Next workout is the next day after your last finished programmed session in the active program, wrapping with modulo. If you have never logged a programmed day, it starts at day one. Empty workouts do not count."
            )
        }
    }
}
