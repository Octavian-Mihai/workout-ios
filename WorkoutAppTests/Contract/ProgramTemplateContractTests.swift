import Testing
import Foundation
import SwiftData
@testable import WorkoutApp

/// Anchors `Bundle(for:)` so the shared contract fixture (copied into the test
/// bundle from the repo-root `contract/` directory) can be located.
private final class ContractBundleToken {}

private func loadContractFixture() -> Data {
    let bundle = Bundle(for: ContractBundleToken.self)
    guard let url = bundle.url(forResource: "program-template.fixture", withExtension: "json") else {
        fatalError("Missing shared contract fixture: contract/program-template.fixture.json")
    }
    return try! Data(contentsOf: url)
}

/// Verifies the iOS app can decode the exact JSON shape the web program-builder
/// produces (program-builder/app.js: buildExportObject + prettyJSON), using the
/// fixture shared with program-builder/tests/contract.test.js. If either side's
/// schema drifts, one of these two test suites should fail.
@Suite("ProgramTemplateFile contract")
struct ProgramTemplateContractTests {
    @Test("decodes the shared web-builder-shaped fixture into the expected ProgramTemplateFile")
    func decodesSharedFixture() throws {
        let data = loadContractFixture()
        let file = try ProgramTemplateService.decode(data)

        #expect(file.version == 1)
        #expect(file.program.uuid.uuidString.lowercased() == "11111111-1111-1111-1111-111111111111")
        #expect(file.program.name == "Push Pull Legs")
        #expect(file.program.isActive == false)
        #expect(file.program.days.count == 2)

        let push = try #require(file.program.days.first { $0.name == "Push" })
        #expect(push.sortIndex == 0)
        #expect(push.exercises.count == 2)

        let bench = try #require(push.exercises.first { $0.name == "Barbell Bench Press" })
        #expect(bench.primaryMuscles == ["Chest"])
        #expect(bench.secondaryMuscles == ["Anterior Delts", "Triceps"])
        #expect(bench.targetSets == 4)
        #expect(bench.targetReps == 8)
        #expect(bench.equipment == "barbell")
        // The web export omits restSeconds entirely (no key in the fixture JSON);
        // it must still decode to nil rather than fail, since ExerciseBackup
        // declares it Optional.
        #expect(bench.restSeconds == nil)
    }

    @Test("importTemplate wires up a program from the shared web-builder-shaped fixture")
    @MainActor
    func importsSharedFixtureIntoSwiftData() throws {
        let schema = Schema([Program.self, ProgramDay.self, DayExercise.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let file = try ProgramTemplateService.decode(loadContractFixture())
        try ProgramTemplateService.importTemplate(file, context: context, existingPrograms: [])

        let programs = try context.fetch(FetchDescriptor<Program>())
        #expect(programs.count == 1)
        let program = try #require(programs.first)
        #expect(program.name == "Push Pull Legs")
        #expect(program.orderedDays.map(\.name) == ["Push", "Pull"])
        #expect(program.orderedDays.first?.orderedExercises.first?.name == "Barbell Bench Press")
    }

    @Test("re-encoding a decoded fixture round-trips to an equal ProgramTemplateFile")
    func reencodingRoundTrips() throws {
        let original = try ProgramTemplateService.decode(loadContractFixture())
        let reencoded = try ProgramTemplateService.encode(original)
        let decodedAgain = try ProgramTemplateService.decode(reencoded)
        #expect(decodedAgain.program == original.program)
        #expect(decodedAgain.version == original.version)
    }
}
