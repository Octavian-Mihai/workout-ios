import Foundation

enum Formatters {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    static let month: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    static func duration(_ seconds: Int) -> String {
        let s = max(seconds, 0)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    static func duration(_ interval: TimeInterval) -> String {
        duration(Int(interval.rounded()))
    }

    static func pace(_ minutesPerUnit: Double, unit: DistanceUnit = .km) -> String {
        guard minutesPerUnit.isFinite, minutesPerUnit > 0 else { return "—" }
        let minutes = Int(minutesPerUnit)
        let seconds = Int((minutesPerUnit - Double(minutes)) * 60)
        return String(format: "%d:%02d /%@", minutes, seconds, unit.title)
    }

    static func distance(_ meters: Double, unit: DistanceUnit) -> String {
        String(format: "%.2f %@", unit.fromMeters(meters), unit.title)
    }

    static func compactNumber(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        if value >= 100 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
