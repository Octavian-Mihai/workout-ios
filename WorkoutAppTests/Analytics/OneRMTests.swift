import Testing
@testable import WorkoutApp

@Suite("OneRM")
struct OneRMTests {
    @Test("zero reps and zero RIR returns the raw weight")
    func zeroRepsZeroRIR() {
        #expect(OneRM.estimate(weight: 100, reps: 0, rir: 0) == 100)
    }

    @Test("one rep at zero RIR adds 1/30 of weight")
    func oneRepZeroRIR() {
        let expected = 100.0 * (1.0 + 1.0 / 30.0)
        #expect(OneRM.estimate(weight: 100, reps: 1, rir: 0) == expected)
    }

    @Test("negative RIR is clamped to zero, not subtracted")
    func negativeRIRClamped() {
        let baseline = OneRM.estimate(weight: 100, reps: 5, rir: 0)
        let withNegativeRIR = OneRM.estimate(weight: 100, reps: 5, rir: -3)
        #expect(withNegativeRIR == baseline)
    }

    @Test("negative reps is clamped to zero, not subtracted")
    func negativeRepsClamped() {
        let baseline = OneRM.estimate(weight: 100, reps: 0, rir: 2)
        let withNegativeReps = OneRM.estimate(weight: 100, reps: -4, rir: 2)
        #expect(withNegativeReps == baseline)
    }

    @Test("high reps matches hand-computed Epley value")
    func highReps() {
        let expected = 80.0 * (1.0 + 20.0 / 30.0)
        #expect(OneRM.estimate(weight: 80, reps: 20, rir: 0) == expected)
    }

    @Test("Romanian deadlift does not match the deadlift family")
    func romanianDeadliftExcluded() {
        #expect(!BigLift.deadlift.matches("Romanian Deadlift"))
    }

    @Test("hack squat does not match the squat family")
    func hackSquatExcluded() {
        #expect(!BigLift.squat.matches("Hack Squat"))
    }

    @Test("bench press matches the bench family")
    func benchPressMatches() {
        #expect(BigLift.bench.matches("Barbell Bench Press"))
    }
}
