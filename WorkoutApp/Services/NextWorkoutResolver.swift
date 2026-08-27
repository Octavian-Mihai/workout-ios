import Foundation

enum NextWorkoutResolver {
    /// Next day in the active program rotation after the last *programmed* session.
    /// Empty workouts do not advance the rotation.
    /// If there is no programmed session for this program, returns day 0.
    static func nextDay(activeProgram: Program?, sessions: [WorkoutSession]) -> ProgramDay? {
        guard let program = activeProgram else { return nil }
        let days = program.orderedDays
        guard !days.isEmpty else { return nil }

        let programmed = sessions
            .filter { session in
                session.isProgrammed
                    && session.endDate != nil
                    && session.programUUID == program.uuid
            }
            .sorted { $0.startDate > $1.startDate }

        guard let last = programmed.first, let lastIndex = last.programDayIndex, !days.isEmpty else {
            return days[0]
        }

        let nextIndex = (lastIndex + 1) % days.count
        if nextIndex >= 0 && nextIndex < days.count {
            return days[nextIndex]
        }
        return days[0]
    }

    static func nextDayIndex(activeProgram: Program?, sessions: [WorkoutSession]) -> Int? {
        guard let day = nextDay(activeProgram: activeProgram, sessions: sessions) else { return nil }
        return day.sortIndex
    }
}
