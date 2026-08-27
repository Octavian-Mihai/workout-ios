import Foundation
import SwiftData
import UniformTypeIdentifiers
import CoreTransferable

struct WorkoutBackupFile: Codable, Transferable {
    var version: Int
    var exportedAt: Date
    var programs: [ProgramBackup]
    var sessions: [SessionBackup]
    var bodyWeights: [BodyWeightBackup]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("workout-data.json")
            let data = try WorkoutBackupService.encode(file)
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

struct ProgramBackup: Codable {
    var uuid: UUID
    var name: String
    var isActive: Bool
    var createdAt: Date
    var days: [DayBackup]
}

struct DayBackup: Codable {
    var uuid: UUID
    var name: String
    var sortIndex: Int
    var exercises: [ExerciseBackup]
}

struct ExerciseBackup: Codable {
    var name: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var targetSets: Int
    var targetReps: Int
    var sortIndex: Int
}

struct SessionBackup: Codable {
    var uuid: UUID
    var startDate: Date
    var endDate: Date?
    var source: String
    var programUUID: UUID?
    var programDayIndex: Int?
    var programDayName: String?
    var durationSeconds: Int
    var sets: [SetBackup]
}

struct SetBackup: Codable {
    var exerciseName: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var weight: Double
    var reps: Int
    var rir: Int
    var targetReps: Int?
    var timestamp: Date
}

struct BodyWeightBackup: Codable {
    var date: Date
    var kilograms: Double
}

enum WorkoutBackupService {
    static func make(
        programs: [Program],
        sessions: [WorkoutSession],
        weights: [BodyWeightEntry]
    ) -> WorkoutBackupFile {
        WorkoutBackupFile(
            version: 1,
            exportedAt: Date(),
            programs: programs.map { program in
                ProgramBackup(
                    uuid: program.uuid,
                    name: program.name,
                    isActive: program.isActive,
                    createdAt: program.createdAt,
                    days: program.orderedDays.map { day in
                        DayBackup(
                            uuid: day.uuid,
                            name: day.name,
                            sortIndex: day.sortIndex,
                            exercises: day.orderedExercises.map { item in
                                ExerciseBackup(
                                    name: item.name,
                                    primaryMuscles: item.primaryMuscles,
                                    secondaryMuscles: item.secondaryMuscles,
                                    targetSets: item.targetSets,
                                    targetReps: item.targetReps,
                                    sortIndex: item.sortIndex
                                )
                            }
                        )
                    }
                )
            },
            sessions: sessions.map { session in
                SessionBackup(
                    uuid: session.uuid,
                    startDate: session.startDate,
                    endDate: session.endDate,
                    source: session.source,
                    programUUID: session.programUUID,
                    programDayIndex: session.programDayIndex,
                    programDayName: session.programDayName,
                    durationSeconds: session.durationSeconds,
                    sets: session.orderedSets.map { log in
                        SetBackup(
                            exerciseName: log.exerciseName,
                            primaryMuscles: log.primaryMuscles,
                            secondaryMuscles: log.secondaryMuscles,
                            weight: log.weight,
                            reps: log.reps,
                            rir: log.rir,
                            targetReps: log.targetReps,
                            timestamp: log.timestamp
                        )
                    }
                )
            },
            bodyWeights: weights.map { BodyWeightBackup(date: $0.date, kilograms: $0.kilograms) }
        )
    }

    static func encode(_ backup: WorkoutBackupFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> WorkoutBackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WorkoutBackupFile.self, from: data)
    }

    @MainActor
    static func importBackup(
        _ backup: WorkoutBackupFile,
        context: ModelContext,
        existingPrograms: [Program],
        existingSessions: [WorkoutSession],
        existingWeights: [BodyWeightEntry]
    ) throws {
        let existingProgramIDs = Set(existingPrograms.map(\.uuid))
        let existingSessionIDs = Set(existingSessions.map(\.uuid))
        let importedHasActive = backup.programs.contains(where: \.isActive)

        if importedHasActive {
            for program in existingPrograms where program.isActive {
                program.isActive = false
            }
        }

        for program in backup.programs where !existingProgramIDs.contains(program.uuid) {
            let model = Program(name: program.name, isActive: program.isActive)
            model.uuid = program.uuid
            model.createdAt = program.createdAt
            context.insert(model)
            for day in program.days {
                let dayModel = ProgramDay(name: day.name, sortIndex: day.sortIndex)
                dayModel.uuid = day.uuid
                dayModel.program = model
                context.insert(dayModel)
                for item in day.exercises {
                    let exercise = DayExercise(
                        name: item.name,
                        primaryMuscles: item.primaryMuscles,
                        secondaryMuscles: item.secondaryMuscles,
                        targetSets: item.targetSets,
                        targetReps: item.targetReps,
                        sortIndex: item.sortIndex
                    )
                    exercise.day = dayModel
                    context.insert(exercise)
                }
            }
        }

        for session in backup.sessions where !existingSessionIDs.contains(session.uuid) {
            let model = WorkoutSession(
                startDate: session.startDate,
                source: session.source,
                programUUID: session.programUUID,
                programDayIndex: session.programDayIndex,
                programDayName: session.programDayName
            )
            model.uuid = session.uuid
            model.endDate = session.endDate
            model.durationSeconds = session.durationSeconds
            context.insert(model)
            for log in session.sets {
                let set = SetLog(
                    exerciseName: log.exerciseName,
                    primaryMuscles: log.primaryMuscles,
                    secondaryMuscles: log.secondaryMuscles,
                    weight: log.weight,
                    reps: log.reps,
                    rir: log.rir,
                    targetReps: log.targetReps,
                    timestamp: log.timestamp
                )
                set.session = model
                context.insert(set)
            }
        }

        let calendar = Calendar.current
        for weight in backup.bodyWeights {
            let exists = existingWeights.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: weight.date)
                    && abs(entry.kilograms - weight.kilograms) < 0.05
            }
            if !exists {
                context.insert(BodyWeightEntry(date: weight.date, kilograms: weight.kilograms))
            }
        }

        try context.save()
    }
}
