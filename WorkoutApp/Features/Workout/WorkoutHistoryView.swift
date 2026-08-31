import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    let sessions: [WorkoutSession]
    let accent: Color
    let unit: WeightUnit

    @Environment(AppTheme.self) private var theme

    private var finished: [WorkoutSession] {
        sessions.filter { $0.endDate != nil }
    }

    private var twoWeekCutoff: Date {
        Date().addingTimeInterval(-14 * 86_400)
    }

    private var recentSessions: [WorkoutSession] {
        finished.filter { $0.startDate >= twoWeekCutoff }
    }

    private var olderSessions: [WorkoutSession] {
        finished.filter { $0.startDate < twoWeekCutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)

            if finished.isEmpty {
                Text("No completed workouts yet. Finish a session to see it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .opaqueCard()
            } else {
                ForEach(recentSessions) { session in
                    NavigationLink {
                        WorkoutSessionDetailView(session: session, accent: accent, unit: unit)
                    } label: {
                        WorkoutSessionRow(session: session, accent: accent, unit: unit)
                    }
                    .buttonStyle(.plain)
                }

                if !olderSessions.isEmpty {
                    DisclosureGroup("Older than 2 weeks (\(olderSessions.count))") {
                        VStack(spacing: 8) {
                            ForEach(olderSessions) { session in
                                NavigationLink {
                                    WorkoutSessionDetailView(session: session, accent: accent, unit: unit)
                                } label: {
                                    WorkoutSessionRow(session: session, accent: accent, unit: unit)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(14)
                    .opaqueCard()
                }
            }
        }
    }
}

struct WorkoutSessionRow: View {
    let session: WorkoutSession
    let accent: Color
    let unit: WeightUnit

    private var setCount: Int { session.orderedSets.count }

    private var totalVolumeKg: Double {
        StressCalculator.totalVolume(from: session.orderedSets)
    }

    private var dayName: String {
        session.programDayName ?? "Workout"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(Formatters.shortDate.string(from: session.startDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.duration(session.durationSeconds))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
                Text("\(setCount) sets · \(Formatters.compactNumber(unit.fromKg(totalVolumeKg))) \(unit.rawValue)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .opaqueCard()
    }
}

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession
    let accent: Color
    let unit: WeightUnit

    @Environment(AppTheme.self) private var theme

    private var model: WorkoutSummaryModel {
        WorkoutSummaryModel(session: session)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    row("Day", model.dayName)
                    row("Date", Formatters.shortDate.string(from: model.date))
                    row("Duration", Formatters.duration(model.durationSeconds))
                    row("Sets", "\(model.totalSets)")
                    row(
                        "Volume",
                        "\(Formatters.compactNumber(unit.fromKg(model.totalVolumeKg))) \(unit.rawValue)·reps"
                    )
                    row("Exercises", "\(model.exerciseCount)")
                }
                .padding(16)
                .opaqueCard()

                if !model.displayedExercises.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Exercises")
                            .font(.headline)
                        ForEach(model.displayedExercises) { exercise in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(exercise.name)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text("\(exercise.setCount) sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Top \(unit.formatNumber(exercise.topSetWeightKg)) × \(exercise.topSetReps)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(accent)
                                ForEach(exercise.sets) { set in
                                    HStack(spacing: 8) {
                                        Text("\(set.id + 1)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .frame(width: 16, alignment: .trailing)
                                        Text("\(unit.formatNumber(set.weightKg)) × \(set.reps)")
                                            .font(.caption.monospacedDigit())
                                        Text("RIR \(RIRPalette.display(set.rir))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            if exercise.id != model.displayedExercises.last?.id {
                                Divider()
                            }
                        }
                        if model.hiddenExerciseCount > 0 {
                            Text("+ \(model.hiddenExerciseCount) more exercise\(model.hiddenExerciseCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .opaqueCard()
                }
            }
            .padding(16)
        }
        .background(theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}
