import Foundation

enum PersonalRecordTracker {
    static func bestEstimate(for exerciseName: String, in sessions: [WorkoutSession]) -> Double? {
        sessions
            .filter { $0.endDate != nil }
            .flatMap(\.orderedSets)
            .filter { $0.exerciseName.compare(exerciseName, options: .caseInsensitive) == .orderedSame }
            .map { OneRM.estimate(weight: $0.weight, reps: $0.reps, rir: $0.rir) }
            .max()
    }

    static func isNewPR(
        weightKg: Double,
        reps: Int,
        rir: Int,
        exerciseName: String,
        sessions: [WorkoutSession]
    ) -> Bool {
        let estimate = OneRM.estimate(weight: weightKg, reps: reps, rir: rir)
        guard let best = bestEstimate(for: exerciseName, in: sessions) else { return true }
        return estimate > best + 0.001
    }
}
