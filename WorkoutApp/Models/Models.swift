import SwiftData
import Foundation

enum MuscleCSV {
    static func encode(_ muscles: [String]) -> String {
        muscles.joined(separator: ",")
    }

    static func decode(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

enum SessionSource {
    static let programmed = "programmed"
    static let empty = "empty"
}

@Model
final class Program {
    var uuid: UUID
    var name: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ProgramDay.program)
    var days: [ProgramDay]

    init(name: String, isActive: Bool = false) {
        self.uuid = UUID()
        self.name = name
        self.isActive = isActive
        self.createdAt = Date()
        self.days = []
    }

    var orderedDays: [ProgramDay] {
        days.sorted { $0.sortIndex < $1.sortIndex }
    }
}

@Model
final class ProgramDay {
    var uuid: UUID
    var name: String
    var sortIndex: Int
    var program: Program?

    @Relationship(deleteRule: .cascade, inverse: \DayExercise.day)
    var exercises: [DayExercise]

    init(name: String, sortIndex: Int) {
        self.uuid = UUID()
        self.name = name
        self.sortIndex = sortIndex
        self.exercises = []
    }

    var orderedExercises: [DayExercise] {
        exercises.sorted { $0.sortIndex < $1.sortIndex }
    }
}

@Model
final class DayExercise {
    var name: String
    var primaryMusclesCSV: String
    var secondaryMusclesCSV: String
    var targetSets: Int
    var targetReps: Int
    var sortIndex: Int
    var day: ProgramDay?

    init(
        name: String,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        targetSets: Int,
        targetReps: Int,
        sortIndex: Int
    ) {
        self.name = name
        self.primaryMusclesCSV = MuscleCSV.encode(primaryMuscles)
        self.secondaryMusclesCSV = MuscleCSV.encode(secondaryMuscles)
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.sortIndex = sortIndex
    }

    var primaryMuscles: [String] {
        get { MuscleCSV.decode(primaryMusclesCSV) }
        set { primaryMusclesCSV = MuscleCSV.encode(newValue) }
    }

    var secondaryMuscles: [String] {
        get { MuscleCSV.decode(secondaryMusclesCSV) }
        set { secondaryMusclesCSV = MuscleCSV.encode(newValue) }
    }
}

@Model
final class WorkoutSession {
    var uuid: UUID
    var startDate: Date
    var endDate: Date?
    var source: String
    var programUUID: UUID?
    var programDayIndex: Int?
    var programDayName: String?
    var durationSeconds: Int

    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var sets: [SetLog]

    init(
        startDate: Date = Date(),
        source: String,
        programUUID: UUID? = nil,
        programDayIndex: Int? = nil,
        programDayName: String? = nil
    ) {
        self.uuid = UUID()
        self.startDate = startDate
        self.endDate = nil
        self.source = source
        self.programUUID = programUUID
        self.programDayIndex = programDayIndex
        self.programDayName = programDayName
        self.durationSeconds = 0
        self.sets = []
    }

    var isProgrammed: Bool {
        source == SessionSource.programmed
    }

    var orderedSets: [SetLog] {
        sets.sorted { $0.timestamp < $1.timestamp }
    }
}

@Model
final class SetLog {
    var exerciseName: String
    var primaryMusclesCSV: String
    var secondaryMusclesCSV: String
    var weight: Double
    var reps: Int
    var rir: Int
    var targetReps: Int?
    var timestamp: Date
    var session: WorkoutSession?

    init(
        exerciseName: String,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        weight: Double,
        reps: Int,
        rir: Int,
        targetReps: Int?,
        timestamp: Date = Date()
    ) {
        self.exerciseName = exerciseName
        self.primaryMusclesCSV = MuscleCSV.encode(primaryMuscles)
        self.secondaryMusclesCSV = MuscleCSV.encode(secondaryMuscles)
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.targetReps = targetReps
        self.timestamp = timestamp
    }

    var primaryMuscles: [String] { MuscleCSV.decode(primaryMusclesCSV) }
    var secondaryMuscles: [String] { MuscleCSV.decode(secondaryMusclesCSV) }

    var volume: Double { weight * Double(reps) }

    var intensityRatio: Double? {
        guard let target = targetReps, target > 0 else { return nil }
        return Double(reps) / Double(target)
    }
}

@Model
final class BodyWeightEntry {
    var date: Date
    var kilograms: Double

    init(date: Date = Date(), kilograms: Double) {
        self.date = date
        self.kilograms = kilograms
    }
}
