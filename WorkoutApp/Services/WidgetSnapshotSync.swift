import Foundation
import WidgetKit

enum WidgetSnapshotSync {
    @MainActor
    static func write(
        sessions: [WorkoutSession],
        programs: [Program],
        cardioWorkouts: [CardioWorkout],
        runDates: Set<Date>,
        restingHeartRate: Double?,
        maxHeartRate: Double?,
        accentHex: String
    ) {
        let snapshot = makeSnapshot(
            sessions: sessions,
            programs: programs,
            cardioWorkouts: cardioWorkouts,
            runDates: runDates,
            restingHeartRate: restingHeartRate,
            maxHeartRate: maxHeartRate,
            accentHex: accentHex
        )
        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    static func makeSnapshot(
        sessions: [WorkoutSession],
        programs: [Program],
        cardioWorkouts: [CardioWorkout],
        runDates: Set<Date>,
        restingHeartRate: Double?,
        maxHeartRate: Double?,
        accentHex: String,
        now: Date = Date()
    ) -> WidgetSnapshot {
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        let recentStart = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now

        var liftDays: Set<TimeInterval> = []
        var liftSessionCount = 0
        for session in sessions where session.endDate != nil {
            let day = cal.startOfDay(for: session.startDate)
            if cal.component(.year, from: day) == year {
                liftDays.insert(day.timeIntervalSince1970)
                liftSessionCount += 1
            }
        }

        var runDays: Set<TimeInterval> = []
        for date in runDates {
            let day = cal.startOfDay(for: date)
            if cal.component(.year, from: day) == year {
                runDays.insert(day.timeIntervalSince1970)
            }
        }

        let activityDays = liftDays.union(runDays)
        let recentActivityDays = activityDays.filter { stamp in
            let day = Date(timeIntervalSince1970: stamp)
            return day >= recentStart
        }.count

        let sets = sessions.flatMap(\.sets)
        let today = StressCalculator.todayEstimate(
            sets: sets,
            cardioWorkouts: cardioWorkouts,
            restingHeartRate: restingHeartRate,
            maxHeartRate: maxHeartRate,
            now: now
        )
        let trend = StressCalculator.dailyTrend(
            sets: sets,
            cardioWorkouts: cardioWorkouts,
            restingHeartRate: restingHeartRate,
            maxHeartRate: maxHeartRate,
            days: 7,
            now: now
        )

        let finished = sessions
            .filter { $0.endDate != nil }
            .sorted { $0.startDate > $1.startDate }
        let last = finished.first
        let lastTitle = last?.programDayName
            ?? (last == nil ? nil : (last!.isProgrammed ? "Workout" : "Empty workout"))

        let active = programs.first(where: \.isActive)
        let next = NextWorkoutResolver.nextDay(activeProgram: active, sessions: sessions)

        return WidgetSnapshot(
            version: 1,
            updatedAt: now,
            year: year,
            dayOfYear: dayOfYear,
            liftDayStarts: Array(liftDays).sorted(),
            runDayStarts: Array(runDays).sorted(),
            activityDayCount: activityDays.count,
            liftSessionCount: liftSessionCount,
            recentActivityDays: recentActivityDays,
            todayStress: today.total,
            todayLift: today.lift,
            todayRun: today.run,
            trendTotals: trend.map(\.total),
            lastWorkoutTitle: lastTitle,
            lastWorkoutDate: last?.startDate,
            nextDayName: next?.name,
            nextProgramName: active?.name,
            accentHex: accentHex
        )
    }
}
