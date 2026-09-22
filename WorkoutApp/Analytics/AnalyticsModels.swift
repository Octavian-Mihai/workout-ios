import Foundation

/// Plain, storage-agnostic view of a logged set, used by `VolumeAnalytics`.
struct SetEntry {
    let exerciseName: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let weight: Double
    let reps: Int
    let rir: Int
    let timestamp: Date
}

extension SetEntry {
    init(_ log: SetLog) {
        self.init(
            exerciseName: log.exerciseName,
            primaryMuscles: log.primaryMuscles,
            secondaryMuscles: log.secondaryMuscles,
            weight: log.weight,
            reps: log.reps,
            rir: log.rir,
            timestamp: log.timestamp
        )
    }
}
