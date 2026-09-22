import Testing
@testable import WorkoutApp

private typealias PlannedLift = ProgramOverviewSnapshot.PlannedLift

@Suite("ProgramOverviewSnapshot")
struct ProgramOverviewStatsTests {
    @Test("with zero target sets, rows sort by exercise credit instead of set credit")
    func fallsBackToExerciseCreditWhenNoTargetSets() {
        let exercises = [
            PlannedLift(primaryMuscles: ["Chest"], secondaryMuscles: [], targetSets: 0)
        ]
        let snapshot = ProgramOverviewSnapshot.build(name: "Test", dayCount: 1, exercises: exercises)
        #expect(snapshot.usesSetVolume == false)
        #expect(snapshot.rows.first?.exerciseCredit == 1)
        #expect(snapshot.rows.first?.setCredit == 0)
    }

    @Test("a muscle listed as both primary and secondary on the same exercise is not double-credited as secondary")
    func noDoubleCreditWhenMuscleIsBothPrimaryAndSecondary() {
        let exercises = [
            PlannedLift(primaryMuscles: ["Chest"], secondaryMuscles: ["Chest", "Triceps"], targetSets: 3)
        ]
        let snapshot = ProgramOverviewSnapshot.build(name: "Test", dayCount: 1, exercises: exercises)
        let chest = snapshot.rows.first { $0.name == "Chest" }
        // Chest counted only as primary: 1 exercise credit, 3 set credit (not +0.5/+1.5 from secondary).
        #expect(chest?.exerciseCredit == 1)
        #expect(chest?.setCredit == 3)
        let triceps = snapshot.rows.first { $0.name == "Triceps" }
        #expect(triceps?.exerciseCredit == 0.5)
        #expect(triceps?.setCredit == 1.5)
    }

    @Test("region groups sum credit across every muscle that maps to that region")
    func regionGroupsSumAcrossMuscles() {
        let exercises = [
            PlannedLift(primaryMuscles: ["Chest"], secondaryMuscles: [], targetSets: 3),
            PlannedLift(primaryMuscles: ["Lats"], secondaryMuscles: [], targetSets: 4)
        ]
        let snapshot = ProgramOverviewSnapshot.build(name: "Test", dayCount: 1, exercises: exercises)
        let upperBody = snapshot.regionGroups.first { $0.name == "Upper body" }
        #expect(upperBody?.exerciseCredit == 2)
        #expect(upperBody?.setCredit == 7)
    }

    @Test("no exercises produces only the empty-rotation insight")
    func emptyProgramInsight() {
        let snapshot = ProgramOverviewSnapshot.build(name: "Test", dayCount: 0, exercises: [])
        #expect(snapshot.insights.count == 1)
        #expect(snapshot.insights.first?.contains("No exercises") == true)
    }

    @Test("an all-lower-body program flags missing upper-body work but not missing arms")
    func allLowerBodyFlagsUpperBodyNotArms() {
        let exercises = [
            PlannedLift(primaryMuscles: ["Quadriceps"], secondaryMuscles: [], targetSets: 3),
            PlannedLift(primaryMuscles: ["Hamstrings"], secondaryMuscles: [], targetSets: 3)
        ]
        let snapshot = ProgramOverviewSnapshot.build(name: "Test", dayCount: 1, exercises: exercises)
        #expect(snapshot.insights.contains { $0.contains("No upper-body work") })
        #expect(!snapshot.insights.contains { $0.contains("arm credit") })
    }

    @Test("a strong push/pull imbalance produces the pressing-outweighs-pulling note")
    func pushPullImbalanceFlagsPressingDominance() {
        let exercises = [
            PlannedLift(primaryMuscles: ["Chest"], secondaryMuscles: [], targetSets: 10),
            PlannedLift(primaryMuscles: ["Lats"], secondaryMuscles: [], targetSets: 2)
        ]
        let snapshot = ProgramOverviewSnapshot.build(name: "Test", dayCount: 1, exercises: exercises)
        #expect(snapshot.insights.contains { $0.contains("Pressing outweighs pulling") })
    }
}
