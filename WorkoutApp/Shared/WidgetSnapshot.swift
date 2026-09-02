import Foundation

enum WidgetSnapshotIDs {
    static let appGroup = "group.com.local.WorkoutApp"
    static let fileName = "widget-snapshot.json"
}

/// Compact payload the main app writes and widgets read. No SwiftData / HealthKit.
struct WidgetSnapshot: Codable, Equatable {
    var version: Int
    var updatedAt: Date
    var year: Int
    var dayOfYear: Int
    var liftDayStarts: [Double]
    var runDayStarts: [Double]
    var activityDayCount: Int
    var liftSessionCount: Int
    var recentActivityDays: Int
    var todayStress: Double
    var todayLift: Double
    var todayRun: Double
    var trendTotals: [Double]
    var lastWorkoutTitle: String?
    var lastWorkoutDate: Date?
    var nextDayName: String?
    var nextProgramName: String?
    var accentHex: String

    static let empty = WidgetSnapshot(
        version: 1,
        updatedAt: .distantPast,
        year: Calendar.current.component(.year, from: Date()),
        dayOfYear: Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1,
        liftDayStarts: [],
        runDayStarts: [],
        activityDayCount: 0,
        liftSessionCount: 0,
        recentActivityDays: 0,
        todayStress: 0,
        todayLift: 0,
        todayRun: 0,
        trendTotals: Array(repeating: 0, count: 7),
        lastWorkoutTitle: nil,
        lastWorkoutDate: nil,
        nextDayName: nil,
        nextProgramName: nil,
        accentHex: "FA6B2E"
    )

    static let preview: WidgetSnapshot = {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        guard let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            return .empty
        }
        var lifts: [Double] = []
        var runs: [Double] = []
        for offset in stride(from: 0, through: 240, by: 3) {
            guard let day = cal.date(byAdding: .day, value: offset, to: jan1) else { continue }
            let start = cal.startOfDay(for: day).timeIntervalSince1970
            if offset % 9 == 0 {
                runs.append(start)
            } else {
                lifts.append(start)
            }
            if offset % 15 == 0 {
                runs.append(start)
            }
        }
        return WidgetSnapshot(
            version: 1,
            updatedAt: now,
            year: year,
            dayOfYear: cal.ordinality(of: .day, in: .year, for: now) ?? 180,
            liftDayStarts: lifts,
            runDayStarts: runs,
            activityDayCount: 84,
            liftSessionCount: 72,
            recentActivityDays: 4,
            todayStress: 44,
            todayLift: 48,
            todayRun: 22,
            trendTotals: [18, 24, 31, 40, 36, 42, 44],
            lastWorkoutTitle: "Push A",
            lastWorkoutDate: cal.date(byAdding: .day, value: -1, to: now),
            nextDayName: "Pull B",
            nextProgramName: "Hypertrophy",
            accentHex: "FA6B2E"
        )
    }()
}

enum WidgetYearActivityKind: Int {
    case none = 0
    case weights = 1
    case running = 2
    case both = 3
}

struct WidgetYearCell: Identifiable {
    var id: Date { date }
    var date: Date
    var inYear: Bool
    var kind: WidgetYearActivityKind
}

enum WidgetYearGridBuilder {
    static func cells(
        year: Int,
        liftDayStarts: [Double],
        runDayStarts: [Double],
        calendar: Calendar = .current
    ) -> [WidgetYearCell] {
        var cal = calendar
        cal.firstWeekday = 1

        let liftDays = Set(liftDayStarts.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0)).timeIntervalSince1970 })
        let runDays = Set(runDayStarts.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0)).timeIntervalSince1970 })

        guard let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else { return [] }
        let weekday = cal.component(.weekday, from: jan1)
        let offset = weekday - cal.firstWeekday
        guard let start = cal.date(byAdding: .day, value: -offset, to: jan1) else { return [] }

        var result: [WidgetYearCell] = []
        result.reserveCapacity(53 * 7)
        for i in 0..<(53 * 7) {
            guard let date = cal.date(byAdding: .day, value: i, to: start) else { continue }
            let day = cal.startOfDay(for: date)
            let inYear = cal.component(.year, from: date) == year
            let stamp = day.timeIntervalSince1970
            let hasLift = inYear && liftDays.contains(stamp)
            let hasRun = inYear && runDays.contains(stamp)
            let kind: WidgetYearActivityKind
            switch (hasLift, hasRun) {
            case (true, true): kind = .both
            case (true, false): kind = .weights
            case (false, true): kind = .running
            case (false, false): kind = .none
            }
            result.append(WidgetYearCell(date: date, inYear: inYear, kind: kind))
        }
        return result
    }
}

enum WidgetSnapshotStore {
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetSnapshotIDs.appGroup)
    }

    static func load() -> WidgetSnapshot? {
        guard let url = containerURL?.appendingPathComponent(WidgetSnapshotIDs.fileName),
              let data = try? Data(contentsOf: url)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let url = containerURL?.appendingPathComponent(WidgetSnapshotIDs.fileName) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
