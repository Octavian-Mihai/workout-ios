import Testing
import Foundation
@testable import WorkoutApp

private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    return cal.date(from: components)!
}

private func entry(
    exercise: String = "Bench Press",
    primary: [String] = ["Chest"],
    secondary: [String] = [],
    weight: Double,
    reps: Int,
    rir: Int = 2,
    timestamp: Date = Date()
) -> SetEntry {
    SetEntry(
        exerciseName: exercise,
        primaryMuscles: primary,
        secondaryMuscles: secondary,
        weight: weight,
        reps: reps,
        rir: rir,
        timestamp: timestamp
    )
}

@Suite("VolumeAnalytics")
struct VolumeAnalyticsTests {
    @Test("setVolume is weight times reps")
    func setVolumeIsWeightTimesReps() {
        let set = entry(weight: 100, reps: 5)
        #expect(VolumeAnalytics.setVolume(set) == 500)
    }

    @Test("muscleVolume: primary gets full credit, secondary gets half, across multiple muscle groups")
    func muscleVolumeCreditsPrimaryAndSecondary() {
        let bench = entry(
            primary: ["Chest"],
            secondary: ["Anterior Delts", "Triceps"],
            weight: 100,
            reps: 5
        )
        let volume = VolumeAnalytics.muscleVolume(from: [bench])
        #expect(volume["Chest"] == 500)
        #expect(volume["Anterior Delts"] == 250)
        #expect(volume["Triceps"] == 250)
    }

    @Test("muscleVolume accumulates when the same muscle appears as primary in one set and secondary in another")
    func muscleVolumeAccumulatesAcrossSets() {
        let primarySet = entry(primary: ["Chest"], secondary: [], weight: 100, reps: 5)
        let secondarySet = entry(exercise: "Overhead Press", primary: ["Anterior Delts"], secondary: ["Chest"], weight: 60, reps: 10)
        let volume = VolumeAnalytics.muscleVolume(from: [primarySet, secondarySet])
        // primarySet: Chest 500. secondarySet: Chest secondary = 600 * 0.5 = 300. Total 800.
        #expect(volume["Chest"] == 800)
    }

    @Test("muscleReps mirrors the primary/secondary weighting used for volume")
    func muscleRepsMirrorsWeighting() {
        let bench = entry(primary: ["Chest"], secondary: ["Triceps"], weight: 100, reps: 8)
        let reps = VolumeAnalytics.muscleReps(from: [bench])
        #expect(reps["Chest"] == 8)
        #expect(reps["Triceps"] == 4)
    }

    @Test("totalVolume and totalReps sum across a multi-exercise session")
    func totalVolumeAndReps() {
        let sets = [
            entry(weight: 100, reps: 5),   // 500
            entry(exercise: "Row", weight: 60, reps: 10) // 600
        ]
        #expect(VolumeAnalytics.totalVolume(from: sets) == 1_100)
        #expect(VolumeAnalytics.totalReps(from: sets) == 15)
    }

    @Test("weeklyTrainingLoad buckets sets into the correct Monday-start week, excludes sets before the window, and zero-fills empty weeks")
    func weeklyTrainingLoadBuckets() {
        // The implementation buckets with Calendar.current (firstWeekday = 2), not a fixed
        // timezone, so expected boundaries are derived the same way rather than hardcoded UTC
        // literals — this keeps the test correct regardless of the machine's local timezone.
        var cal = Calendar.current
        cal.firstWeekday = 2
        let now = utc(2024, 1, 17, 12)
        let currentWeekStart = cal.dateInterval(of: .weekOfYear, for: now)!.start
        let earliestWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        let secondWeekStart = currentWeekStart

        let inEarliestWeek = entry(weight: 100, reps: 5, timestamp: earliestWeekStart) // exactly on the boundary
        let beforeWindow = entry(weight: 999, reps: 1, timestamp: earliestWeekStart.addingTimeInterval(-1)) // 1s before, excluded
        let inSecondWeek = entry(weight: 50, reps: 2, timestamp: secondWeekStart.addingTimeInterval(12 * 3600))

        let result = VolumeAnalytics.weeklyTrainingLoad(from: [inEarliestWeek, beforeWindow, inSecondWeek], weeks: 2, now: now)

        #expect(result.count == 2)
        #expect(result[0].weekStart == earliestWeekStart)
        #expect(result[0].tonnageKg == 500)
        #expect(result[0].setCount == 1)
        #expect(result[0].repCount == 5)

        #expect(result[1].weekStart == secondWeekStart)
        #expect(result[1].tonnageKg == 100)
        #expect(result[1].setCount == 1)
        #expect(result[1].repCount == 2)
    }

    @Test("weeklyTrainingLoad zero-fills a week with no logged sets")
    func weeklyTrainingLoadZeroFillsEmptyWeek() {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let now = utc(2024, 1, 17, 12)
        let secondWeekStart = cal.dateInterval(of: .weekOfYear, for: now)!.start
        let onlySet = entry(weight: 50, reps: 2, timestamp: secondWeekStart.addingTimeInterval(3600))

        let result = VolumeAnalytics.weeklyTrainingLoad(from: [onlySet], weeks: 2, now: now)

        #expect(result.count == 2)
        #expect(result[0].tonnageKg == 0)
        #expect(result[0].setCount == 0)
        #expect(result[0].repCount == 0)
    }

    @Test("muscleDailyLoad: volume-only case matches min(60, volume/400) with zero intensity contribution")
    func muscleDailyLoadVolumeOnly() {
        // rir = 5 -> intensity factor max(0, 5-5)/5 = 0
        let set = entry(primary: ["Chest"], weight: 160, reps: 10, rir: 5) // volume 1600 -> volumeScore min(60, 4) = 4
        let load = VolumeAnalytics.muscleDailyLoad(from: [set])
        #expect(load["Chest"] == 4)
    }

    @Test("muscleDailyLoad: high-intensity (low RIR) case adds the intensity term")
    func muscleDailyLoadHighIntensity() {
        // rir = 0 -> intensity factor max(0, 5-0)/5 = 1.0 -> +40
        let set = entry(primary: ["Chest"], weight: 40, reps: 5, rir: 0) // volume 200 -> volumeScore min(60, 0.5) = 0.5
        let load = VolumeAnalytics.muscleDailyLoad(from: [set])
        #expect(load["Chest"] == 40.5)
    }

    @Test("bestEstimated1RM returns the max estimate across matching sets, not the most recent")
    func bestEstimated1RMReturnsMax() {
        let now = utc(2024, 6, 1)
        let older = entry(exercise: "Back Squat", weight: 140, reps: 3, rir: 0, timestamp: now.addingTimeInterval(-10 * 86_400))
        let mostRecentButLighter = entry(exercise: "Back Squat", weight: 100, reps: 3, rir: 0, timestamp: now.addingTimeInterval(-1 * 86_400))
        let best = VolumeAnalytics.bestEstimated1RM(for: "Back Squat", in: [older, mostRecentButLighter], now: now)
        #expect(best == OneRM.estimate(weight: 140, reps: 3, rir: 0))
    }

    @Test("bestEstimated1RM excludes sets older than 90 days")
    func bestEstimated1RMExcludesStaleSets() {
        let now = utc(2024, 6, 1)
        let tooOld = entry(exercise: "Back Squat", weight: 200, reps: 3, rir: 0, timestamp: now.addingTimeInterval(-91 * 86_400))
        let recent = entry(exercise: "Back Squat", weight: 100, reps: 3, rir: 0, timestamp: now.addingTimeInterval(-1 * 86_400))
        let best = VolumeAnalytics.bestEstimated1RM(for: "Back Squat", in: [tooOld, recent], now: now)
        #expect(best == OneRM.estimate(weight: 100, reps: 3, rir: 0))
    }

    @Test("bestEstimated1RM excludes zero-weight and zero-rep sets")
    func bestEstimated1RMExcludesEmptySets() {
        let now = utc(2024, 6, 1)
        let zeroWeight = entry(exercise: "Back Squat", weight: 0, reps: 5, rir: 0, timestamp: now)
        let zeroReps = entry(exercise: "Back Squat", weight: 100, reps: 0, rir: 0, timestamp: now)
        let best = VolumeAnalytics.bestEstimated1RM(for: "Back Squat", in: [zeroWeight, zeroReps], now: now)
        #expect(best == 0)
    }
}
