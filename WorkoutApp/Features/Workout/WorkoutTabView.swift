import SwiftUI
import SwiftData
import Charts

struct WorkoutTabView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Program.createdAt) private var programs: [Program]
    @EnvironmentObject private var sessionStore: ActiveSessionStore
    @Environment(AppTheme.self) private var theme
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue

    private var accent: Color { theme.accent }
    private var unit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }

    private var activeProgram: Program? {
        programs.first(where: \.isActive)
    }

    private var nextDay: ProgramDay? {
        NextWorkoutResolver.nextDay(activeProgram: activeProgram, sessions: sessions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProgramListView()

                    if let program = activeProgram, let day = nextDay {
                        Button {
                            sessionStore.start(program: program, programDay: day)
                        } label: {
                            Label("Start \(day.name)", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityHint("Starts \(program.name)")
                    }

                    Button {
                        sessionStore.start(program: nil, programDay: nil)
                    } label: {
                        Label("Start empty workout", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)

                    LearnLinksView()

                    WorkoutHistoryView(sessions: sessions, accent: accent, unit: unit)
                }
                .padding(16)
            }
            .background(theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Workout")
        }
    }
}

struct StrengthAnalyticsView: View {
    let sets: [SetLog]
    let accent: Color

    @Environment(AppTheme.self) private var theme
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage(InfoPageVisibility.showTonnageKey) private var showTonnage = true
    @AppStorage(InfoPageVisibility.showVolumeChartsKey) private var showVolumeCharts = true
    @AppStorage(InfoPageVisibility.showEstimated1RMKey) private var showEstimated1RM = true
    @AppStorage(InfoPageVisibility.showIntensityMapKey) private var showIntensityMap = true

    private var unit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var recent: [SetLog] { StressCalculator.sets(inLastDays: 7, from: sets) }
    private var muscleVolume: [(String, Double)] {
        StressCalculator.muscleVolume(from: recent)
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    private var muscleLoads: [(name: String, tonnageKg: Double, reps: Double)] {
        let reps = StressCalculator.muscleReps(from: recent)
        return muscleVolume.map { ($0.0, $0.1, reps[$0.0] ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showTonnage {
                tonnageSummary
            }
            if showVolumeCharts {
                volumeChart
                engagementChart
            }
            if showEstimated1RM {
                oneRMChart
            }
            if showIntensityMap {
                intensityMap
            }
        }
    }

    private var tonnageSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            if recent.isEmpty {
                Text("Log sets to see tonnage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("Tonnage (7d)")
                    Spacer()
                    Text("\(Formatters.compactNumber(unit.fromKg(StressCalculator.totalVolume(from: recent)))) \(unit.rawValue)·reps")
                        .monospacedDigit()
                }
                .font(.subheadline)
                HStack {
                    Text("Reps (7d)")
                    Spacer()
                    Text("\(StressCalculator.totalReps(from: recent))")
                        .monospacedDigit()
                }
                .font(.subheadline)
                ForEach(muscleLoads, id: \.name) { row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.name)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Formatters.compactNumber(unit.fromKg(row.tonnageKg))) \(unit.rawValue)·reps")
                                .monospacedDigit()
                            Text("\(Formatters.trimmedNumber(row.reps, decimals: 1)) reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private var volumeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volume per muscle (7d)")
                .font(.headline)
            Text("Primary gets full set volume; secondary gets half.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if muscleVolume.isEmpty {
                Text("Log sets to see muscle volume.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(muscleVolume, id: \.0) { item in
                    BarMark(
                        x: .value("Volume", unit.fromKg(item.1)),
                        y: .value("Muscle", item.0)
                    )
                    .foregroundStyle(accent)
                }
                .frame(height: max(160, CGFloat(muscleVolume.count) * 22))
                .chartXAxisLabel(unit.rawValue + "·reps")
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private var oneRMChart: some View {
        let series = oneRMSeries()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Estimated 1RM")
                .font(.headline)
            Text("weight × (1 + (reps + RIR) / 30)")
                .font(.caption)
                .foregroundStyle(.secondary)
            if series.isEmpty {
                Text("Squat, bench, deadlift, OHP, and row will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(series) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", unit.fromKg(point.value))
                    )
                    .foregroundStyle(by: .value("Lift", point.lift))
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", unit.fromKg(point.value))
                    )
                    .foregroundStyle(by: .value("Lift", point.lift))
                }
                .frame(height: 220)
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private var engagementChart: some View {
        let data = muscleVolume
        return VStack(alignment: .leading, spacing: 8) {
            Text("Muscle engagement (7d)")
                .font(.headline)
            if data.isEmpty {
                Text("No sets in the last 7 days.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data, id: \.0) { item in
                    BarMark(
                        x: .value("Muscle", item.0),
                        y: .value("Volume", unit.fromKg(item.1))
                    )
                    .foregroundStyle(accent.opacity(0.85))
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(orientation: .vertical)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private var intensityMap: some View {
        let rows = intensityRows()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Intensity map")
                .font(.headline)
            Text("Average RIR per exercise over the last 7 days.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if rows.isEmpty {
                Text("Intensity appears after you log sets.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rows) { row in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.exercise)
                                .font(.subheadline.weight(.semibold))
                            Text(row.muscle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        RIRBadge(rir: row.avgRIR, accent: accent)
                    }
                    GeometryReader { geo in
                        Capsule()
                            .fill(theme.mutedFill)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(RIRPalette.color(for: row.avgRIR, accent: accent))
                                    .frame(width: geo.size.width * min(max(row.heat, 0.08), 1))
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private func oneRMSeries() -> [LiftPoint] {
        var points: [LiftPoint] = []
        for lift in BigLift.allCases {
            let matching = sets
                .filter { lift.matches($0.exerciseName) && $0.weight > 0 && $0.reps > 0 }
                .sorted { $0.timestamp < $1.timestamp }
            var bestByDay: [Date: Double] = [:]
            let cal = Calendar.current
            for set in matching {
                let day = cal.startOfDay(for: set.timestamp)
                let est = OneRM.estimate(weight: set.weight, reps: set.reps, rir: set.rir)
                bestByDay[day] = max(bestByDay[day] ?? 0, est)
            }
            for (day, value) in bestByDay.sorted(by: { $0.key < $1.key }) {
                points.append(LiftPoint(id: "\(lift.rawValue)-\(day.timeIntervalSince1970)", lift: lift.rawValue, date: day, value: value))
            }
        }
        return points
    }

    private func intensityRows() -> [IntensityRow] {
        let grouped = Dictionary(grouping: recent, by: \.exerciseName)
        return grouped.map { name, items in
            let avgRIR = Int((items.map { Double($0.rir) }.reduce(0, +) / Double(max(items.count, 1))).rounded())
            let heat = max(0, 5.0 - Double(min(avgRIR, 5))) / 5.0
            return IntensityRow(
                id: name,
                exercise: name,
                muscle: items.first?.primaryMuscles.first ?? "—",
                avgRIR: avgRIR,
                heat: heat
            )
        }
        .sorted { $0.heat > $1.heat }
    }
}

struct LiftPoint: Identifiable {
    let id: String
    let lift: String
    let date: Date
    let value: Double
}

struct IntensityRow: Identifiable {
    let id: String
    let exercise: String
    let muscle: String
    let avgRIR: Int
    let heat: Double
}
