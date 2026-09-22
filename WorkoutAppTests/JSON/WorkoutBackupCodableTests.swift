import Testing
import Foundation
@testable import WorkoutApp

/// Anchors `Bundle(for:)` so fixture JSON files copied into the test bundle can be located.
private final class FixtureBundleToken {}

private func loadFixture(_ name: String) -> Data {
    let bundle = Bundle(for: FixtureBundleToken.self)
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
        fatalError("Missing fixture: \(name).json")
    }
    return try! Data(contentsOf: url)
}

private func fullFixtureBackup() -> WorkoutBackupFile {
    WorkoutBackupFile(
        version: 2,
        exportedAt: iso("2024-03-01T12:00:00Z"),
        programs: [
            ProgramBackup(
                uuid: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                name: "Push Pull Legs",
                isActive: true,
                createdAt: iso("2024-01-01T00:00:00Z"),
                days: [
                    DayBackup(
                        uuid: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                        name: "Push Day",
                        sortIndex: 0,
                        exercises: [
                            ExerciseBackup(
                                name: "Bench Press",
                                primaryMuscles: ["Chest"],
                                secondaryMuscles: ["Anterior Delts", "Triceps"],
                                targetSets: 4,
                                targetReps: 8,
                                sortIndex: 0,
                                equipment: "Barbell",
                                restSeconds: 120
                            ),
                            ExerciseBackup(
                                name: "Push-up",
                                primaryMuscles: ["Chest"],
                                secondaryMuscles: [],
                                targetSets: 3,
                                targetReps: 12,
                                sortIndex: 1,
                                equipment: nil,
                                restSeconds: nil
                            )
                        ]
                    )
                ]
            )
        ],
        sessions: [
            SessionBackup(
                uuid: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                startDate: iso("2024-03-01T09:00:00Z"),
                endDate: iso("2024-03-01T10:00:00Z"),
                source: "manual",
                programUUID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                programDayIndex: 0,
                programDayName: "Push Day",
                durationSeconds: 3_600,
                sets: [
                    SetBackup(
                        exerciseName: "Bench Press",
                        primaryMuscles: ["Chest"],
                        secondaryMuscles: ["Triceps"],
                        weight: 100.0,
                        reps: 5,
                        rir: 2,
                        targetReps: 8,
                        timestamp: iso("2024-03-01T09:05:00Z")
                    ),
                    SetBackup(
                        exerciseName: "Push-up",
                        primaryMuscles: ["Chest"],
                        secondaryMuscles: [],
                        weight: 0.0,
                        reps: 20,
                        rir: 3,
                        targetReps: nil,
                        timestamp: iso("2024-03-01T09:30:00Z")
                    )
                ]
            )
        ],
        bodyWeights: [
            BodyWeightBackup(date: iso("2024-03-01T07:00:00Z"), kilograms: 82.5)
        ],
        measurements: [
            MeasurementBackup(
                date: iso("2024-03-01T07:05:00Z"),
                photoFilename: nil,
                kilograms: 82.5,
                caloriesKcal: 2_400,
                heightCm: 180.0,
                neckCm: nil,
                shouldersCm: nil,
                chestCm: 102.0,
                leftBicepsCm: nil,
                rightBicepsCm: nil,
                leftForearmCm: nil,
                rightForearmCm: nil,
                waistCm: 84.0,
                hipsCm: nil,
                leftThighCm: nil,
                rightThighCm: nil,
                leftCalfCm: nil,
                rightCalfCm: nil
            )
        ]
    )
}

private func iso(_ string: String) -> Date {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: string)!
}

@Suite("WorkoutBackupFile codable")
struct WorkoutBackupCodableTests {
    @Test("encoding then decoding a fully populated backup returns an equal value")
    func encodeDecodeRoundTrip() throws {
        let original = fullFixtureBackup()
        let data = try WorkoutBackupService.encode(original)
        let decoded = try WorkoutBackupService.decode(data)
        #expect(decoded == original)
    }

    @Test("decoding the checked-in fixture JSON matches the hand-built equivalent")
    func decodesFixtureFile() throws {
        let data = loadFixture("workout-backup-fixture")
        let decoded = try WorkoutBackupService.decode(data)
        #expect(decoded == fullFixtureBackup())
    }

    @Test("a legacy v1 payload with no top-level measurements key decodes with an empty measurements array")
    func decodesLegacyPayloadWithoutMeasurements() throws {
        let data = loadFixture("workout-backup-fixture-legacy-v1")
        let decoded = try WorkoutBackupService.decode(data)
        #expect(decoded.version == 1)
        #expect(decoded.measurements.isEmpty)
        #expect(decoded.programs.isEmpty)
        #expect(decoded.sessions.count == 1)
        #expect(decoded.sessions.first?.sets.first?.exerciseName == "Squat")
        #expect(decoded.bodyWeights.first?.kilograms == 80.0)
    }

    @Test("nil optionals round-trip as nil, not as missing keys or defaults")
    func nilOptionalsRoundTrip() throws {
        let original = fullFixtureBackup()
        let data = try WorkoutBackupService.encode(original)
        let decoded = try WorkoutBackupService.decode(data)

        let pushUp = decoded.programs.first?.days.first?.exercises.last
        #expect(pushUp?.equipment == nil)
        #expect(pushUp?.restSeconds == nil)

        let bodyweightSet = decoded.sessions.first?.sets.last
        #expect(bodyweightSet?.targetReps == nil)

        let measurement = decoded.measurements.first
        #expect(measurement?.neckCm == nil)
        #expect(measurement?.hipsCm == nil)
    }

    @Test("empty top-level collections round-trip as empty arrays, not null")
    func emptyCollectionsRoundTrip() throws {
        let empty = WorkoutBackupFile(
            version: 2,
            exportedAt: iso("2024-01-01T00:00:00Z"),
            programs: [],
            sessions: [],
            bodyWeights: [],
            measurements: []
        )
        let data = try WorkoutBackupService.encode(empty)
        let decoded = try WorkoutBackupService.decode(data)
        #expect(decoded == empty)
    }
}
