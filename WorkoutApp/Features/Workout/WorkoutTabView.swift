import SwiftUI
import SwiftData
import Charts

struct WorkoutTabView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Program.createdAt) private var programs: [Program]
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @State private var showEmptySession = false
    @State private var showProgrammedSession = false
    @State private var showTrends = false
    @StateObject private var health = HealthKitService()

    private var accent: Color {
        AccentOption(rawValue: accentName)?.color ?? .orange
    }

    private var activeProgram: Program? {
        programs.first(where: \.isActive)
    }

    private var nextDay: ProgramDay? {
        NextWorkoutResolver.nextDay(activeProgram: activeProgram, sessions: sessions)
    }

    private var allSets: [SetLog] {
        sessions.flatMap(\.sets)
    }

    private var weeklyRunStress: Double {
        StressCalculator.averageRunStress(health.runs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProgramListView()

                    if let program = activeProgram, let day = nextDay {
                        Button {
                            showProgrammedSession = true
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
                        showEmptySession = true
                    } label: {
                        Label("Start empty workout", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)

                    YearActivityGrid(sessions: sessions) { _ in
                        showTrends = true
                    }

                    StrengthAnalyticsView(
                        sets: allSets,
                        runStress: weeklyRunStress,
                        accent: accent
                    )
                }
                .padding(16)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Workout")
            .navigationDestination(isPresented: $showEmptySession) {
                LiveSessionView(program: nil, programDay: nil)
            }
            .navigationDestination(isPresented: $showProgrammedSession) {
                LiveSessionView(program: activeProgram, programDay: nextDay)
            }
            .navigationDestination(isPresented: $showTrends) {
                TrendsDetailView()
            }
            .task {
                if health.isAvailable {
                    await health.requestAndLoad()
                }
            }
        }
    }
}

struct StrengthAnalyticsView: View {
    let sets: [SetLog]
    let runStress: Double
    let accent: Color

    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue

    private var unit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var recent: [SetLog] { StressCalculator.sets(inLastDays: 7, from: sets) }
    private var csi: Double { StressCalculator.centralStress(sets: sets) }
    private var tsi: Double { StressCalculator.totalStress(sets: sets, runStress: runStress) }
    private var recovery: Double { StressCalculator.recoveryScore(totalStress: tsi) }
    private var muscleVolume: [(String, Double)] {
        StressCalculator.muscleVolume(from: recent)
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics")
                .font(.title3.weight(.bold))

            VStack(alignment: .leading, spacing: 16) {
                StressMeter(title: "Central stress (7d)", score: csi, accent: accent)
                StressMeter(title: "Total stress (7d)", score: tsi, accent: accent)
                StressMeter(title: "Recovery", score: recovery, accent: accent)
                HStack {
                    Text("Total volume (7d)")
                    Spacer()
                    Text("\(Formatters.compactNumber(unit.fromKg(StressCalculator.totalVolume(from: recent)))) \(unit.rawValue)·reps")
                        .monospacedDigit()
                }
                .font(.subheadline)
                StressLegendView(compact: true)
            }
            .padding(16)
            .opaqueCard()

            volumeChart
            oneRMChart
            engagementChart
            intensityMap
        }
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
            Text("RIR color plus actual reps / target reps when a target exists.")
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
                        if let ratio = row.ratio {
                            Text("\(Int((ratio * 100).rounded()))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    GeometryReader { geo in
                        Capsule()
                            .fill(Theme.mutedFill)
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
            let ratios = items.compactMap(\.intensityRatio)
            let ratio = ratios.isEmpty ? nil : ratios.reduce(0, +) / Double(ratios.count)
            let rirHeat = max(0, 5.0 - Double(min(avgRIR, 5))) / 5.0
            let heat = ratio.map { min(1, ($0 * 0.5) + (rirHeat * 0.5)) } ?? rirHeat
            return IntensityRow(
                id: name,
                exercise: name,
                muscle: items.first?.primaryMuscles.first ?? "—",
                avgRIR: avgRIR,
                ratio: ratio,
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
    let ratio: Double?
    let heat: Double
}
