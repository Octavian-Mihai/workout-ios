import Foundation
import SwiftData
import UniformTypeIdentifiers
import CoreTransferable

struct ProgramTemplateFile: Codable, Transferable {
    var version: Int
    var exportedAt: Date
    var program: ProgramBackup

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            let sanitized = file.program.name
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            let filename = sanitized.isEmpty ? "program" : "program-\(sanitized)"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(filename).json")
            let data = try ProgramTemplateService.encode(file)
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

enum ProgramTemplateService {
    static func make(from program: Program) -> ProgramTemplateFile {
        ProgramTemplateFile(
            version: 1,
            exportedAt: Date(),
            program: WorkoutBackupService.programBackup(from: program)
        )
    }

    static func encode(_ file: ProgramTemplateFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(file)
    }

    static func decode(_ data: Data) throws -> ProgramTemplateFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ProgramTemplateFile.self, from: data)
    }

    @MainActor
    static func importTemplate(
        _ file: ProgramTemplateFile,
        context: ModelContext,
        existingPrograms: [Program]
    ) throws {
        let existingNames = Set(existingPrograms.map(\.name))
        var programName = file.program.name
        if existingNames.contains(programName) {
            programName += " (imported)"
        }

        let model = Program(name: programName, isActive: false)
        model.createdAt = file.program.createdAt
        context.insert(model)

        for day in file.program.days.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            let dayModel = ProgramDay(name: day.name, sortIndex: day.sortIndex)
            dayModel.program = model
            context.insert(dayModel)
            for item in day.exercises.sorted(by: { $0.sortIndex < $1.sortIndex }) {
                let equipment = ExerciseEquipment.resolve(raw: item.equipment, name: item.name)
                let exercise = DayExercise(
                    name: item.name,
                    primaryMuscles: item.primaryMuscles,
                    secondaryMuscles: item.secondaryMuscles,
                    targetSets: item.targetSets,
                    targetReps: item.targetReps,
                    sortIndex: item.sortIndex,
                    equipment: equipment
                )
                exercise.day = dayModel
                context.insert(exercise)
            }
        }

        try context.save()
    }
}
