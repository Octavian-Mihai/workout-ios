import Foundation

struct WorkoutSummarySet: Identifiable {
    let id: Int
    let weightKg: Double
    let reps: Int
    let rir: Int
}

struct WorkoutSummaryExercise: Identifiable {
    let id: String
    let name: String
    let setCount: Int
    let topSetWeightKg: Double
    let topSetReps: Int
    let sets: [WorkoutSummarySet]
}

struct WorkoutSummaryModel {
    static let maxDisplayedExercises = 8

    let dayName: String
    let date: Date
    let durationSeconds: Int
    let totalSets: Int
    let totalVolumeKg: Double
    let exerciseCount: Int
    let displayedExercises: [WorkoutSummaryExercise]
    let hiddenExerciseCount: Int

    init(session: WorkoutSession) {
        let sets = session.orderedSets

        dayName = session.programDayName ?? "Workout"
        date = session.startDate
        durationSeconds = session.durationSeconds
        totalSets = sets.count
        totalVolumeKg = StressCalculator.totalVolume(from: sets)

        var exerciseOrder: [String] = []
        var grouped: [String: [SetLog]] = [:]
        for set in sets {
            if grouped[set.exerciseName] == nil {
                exerciseOrder.append(set.exerciseName)
                grouped[set.exerciseName] = []
            }
            grouped[set.exerciseName]?.append(set)
        }

        exerciseCount = exerciseOrder.count

        let allExercises: [WorkoutSummaryExercise] = exerciseOrder.compactMap { name in
            guard let logs = grouped[name], !logs.isEmpty else { return nil }
            let top = logs.max { lhs, rhs in
                OneRM.estimate(weight: lhs.weight, reps: lhs.reps, rir: lhs.rir)
                    < OneRM.estimate(weight: rhs.weight, reps: rhs.reps, rir: rhs.rir)
            }!
            let summarySets = logs.enumerated().map { index, log in
                WorkoutSummarySet(
                    id: index,
                    weightKg: log.weight,
                    reps: log.reps,
                    rir: log.rir
                )
            }
            return WorkoutSummaryExercise(
                id: name,
                name: name,
                setCount: logs.count,
                topSetWeightKg: top.weight,
                topSetReps: top.reps,
                sets: summarySets
            )
        }

        displayedExercises = Array(allExercises.prefix(Self.maxDisplayedExercises))
        hiddenExerciseCount = max(0, allExercises.count - displayedExercises.count)
    }
}
