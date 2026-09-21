import ActivityKit
import Foundation

struct RestTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var restEndDate: Date
        var exerciseName: String
    }

    var sessionLabel: String
}
