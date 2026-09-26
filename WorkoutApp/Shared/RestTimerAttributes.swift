import ActivityKit
import Foundation

struct RestTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var restEndDate: Date
        var exerciseName: String
        var setsCompleted: Int = 0
        var targetSets: Int = 0
    }

    var sessionLabel: String
}
