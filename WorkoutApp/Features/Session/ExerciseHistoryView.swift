import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    let exerciseName: String
    let unit: WeightUnit
    let accent: Color

    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    private var matchingSets: [SetLog] {
        sessions
            .filter { $0.endDate != nil }
            .flatMap(\.orderedSets)
            .filter { $0.exerciseName.compare(exerciseName, options: .caseInsensitive) == .orderedSame }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var bestEstimate: Double {
        matchingSets
            .filter { $0.weight > 0 && $0.reps > 0 }
            .map { OneRM.estimate(weight: $0.weight, reps: $0.reps, rir: $0.rir) }
            .max() ?? 0
    }

    private var chartPoints: [HistoryPoint] {
        let cal = Calendar.current
        var bestByDay: [Date: Double] = [:]
        for set in matchingSets where set.weight > 0 && set.reps > 0 {
            let day = cal.startOfDay(for: set.timestamp)
            let est = OneRM.estimate(weight: set.weight, reps: set.reps, rir: set.rir)
            bestByDay[day] = max(bestByDay[day] ?? 0, est)
        }
        return bestByDay
            .sorted { $0.key < $1.key }
            .map { HistoryPoint(date: $0.key, estimate: $0.value) }
    }

    private var sessionGroups: [(WorkoutSession, [SetLog])] {
        sessions.compactMap { session in
            guard session.endDate != nil else { return nil }
            let sets = session.orderedSets.filter {
                $0.exerciseName.compare(exerciseName, options: .caseInsensitive) == .orderedSame
            }
            return sets.isEmpty ? nil : (session, sets)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                estimateCard

                if chartPoints.count >= 2 {
                    chartCard
                }

                historyCard
            }
            .padding(16)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var estimateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated 1RM")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if bestEstimate > 0 {
                Text(unit.format(bestEstimate))
                    .font(.title.weight(.bold).monospacedDigit())
                Text("Epley formula using reps + RIR from your logged sets.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.title.weight(.bold))
                Text("Log sets with weight and reps to see an estimate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .opaqueCard()
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1RM over time")
                .font(.headline)
            Chart(chartPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("1RM", unit.fromKg(point.estimate))
                )
                .foregroundStyle(accent)
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("1RM", unit.fromKg(point.estimate))
                )
                .foregroundStyle(accent)
            }
            .frame(height: 160)
            .chartYAxisLabel(unit.rawValue)
        }
        .padding(16)
        .opaqueCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session history")
                .font(.headline)
            if sessionGroups.isEmpty {
                Text("No past sessions for this exercise.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sessionGroups.prefix(20), id: \.0.uuid) { session, sets in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Formatters.shortDate.string(from: session.startDate))
                            .font(.subheadline.weight(.semibold))
                        ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                            HStack(spacing: 6) {
                                Text("Set \(index + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 44, alignment: .leading)
                                Text("\(unit.formatNumber(set.weight)) × \(set.reps)")
                                    .font(.caption.monospacedDigit())
                                RIRDot(rir: set.rir, size: 12)
                                Spacer()
                                Text(unit.format(OneRM.estimate(weight: set.weight, reps: set.reps, rir: set.rir)))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    if session.uuid != sessionGroups.prefix(20).last?.0.uuid {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .opaqueCard()
    }
}

private struct HistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let estimate: Double
}
