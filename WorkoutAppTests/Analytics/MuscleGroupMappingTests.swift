import Testing
@testable import WorkoutApp

@Suite("MuscleGroup mapping")
struct MuscleGroupMappingTests {
    @Test("parse round-trips every one of the 20 muscle groups by raw value")
    func parseRoundTripsAllCases() {
        #expect(MuscleGroup.allCases.count == 20)
        for muscle in MuscleGroup.allCases {
            #expect(MuscleGroup.parse(muscle.rawValue) == muscle)
        }
    }

    @Test("parse resolves legacy/alternate import names onto the current catalog")
    func parseResolvesLegacyAliases() {
        #expect(MuscleGroup.parse("Front Delts") == .anteriorDelts)
        #expect(MuscleGroup.parse("Side Delts") == .lateralDelts)
        #expect(MuscleGroup.parse("Rear Delts") == .posteriorDelts)
        #expect(MuscleGroup.parse("Core") == .coreAndAbs)
        #expect(MuscleGroup.parse("Upper Back") == .rhomboids)
        #expect(MuscleGroup.parse("Lower Back") == .erectors)
        #expect(MuscleGroup.parse("Forearms") == .forearmsAndGrip)
        #expect(MuscleGroup.parse("Quads") == .quadriceps)
    }

    @Test("parse returns nil for a name with no known mapping")
    func parseReturnsNilForUnknownName() {
        #expect(MuscleGroup.parse("Not A Real Muscle") == nil)
    }

    @Test("region assigns the muscle groups insights logic depends on to the expected region")
    func regionMapsToExpectedGroup() {
        #expect(MuscleGroup.chest.region == "Upper body")
        #expect(MuscleGroup.biceps.region == "Arms")
        #expect(MuscleGroup.quadriceps.region == "Lower body")
        #expect(MuscleGroup.coreAndAbs.region == "Trunk")
    }

    @Test("every muscle group maps to exactly one of the four regions used by ProgramOverviewSnapshot insights")
    func everyMuscleHasAKnownRegion() {
        let knownRegions: Set<String> = ["Upper body", "Arms", "Lower body", "Trunk"]
        for muscle in MuscleGroup.allCases {
            #expect(knownRegions.contains(muscle.region))
        }
    }
}
