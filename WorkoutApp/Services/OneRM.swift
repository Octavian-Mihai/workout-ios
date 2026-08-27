import Foundation

enum OneRM {
    /// Epley with RIR counted as extra reps: weight × (1 + (reps + RIR) / 30)
    static func estimate(weight: Double, reps: Int, rir: Int) -> Double {
        let extra = Double(max(reps, 0) + max(rir, 0))
        return weight * (1.0 + extra / 30.0)
    }
}

enum BigLift: String, CaseIterable, Identifiable {
    case squat = "Squat"
    case bench = "Bench"
    case deadlift = "Deadlift"
    case ohp = "OHP"
    case row = "Row"

    var id: String { rawValue }

    func matches(_ exerciseName: String) -> Bool {
        let n = exerciseName.lowercased()
        switch self {
        case .squat:
            return n.contains("squat") && !n.contains("split") && !n.contains("hack")
        case .bench:
            return n.contains("bench")
        case .deadlift:
            return n.contains("deadlift")
                && !n.contains("romanian")
                && !n.contains("rdl")
                && !n.contains("stiff")
        case .ohp:
            return n.contains("overhead press")
                || n.contains("ohp")
                || n.contains("military press")
                || (n.contains("shoulder press") && !n.contains("dumbbell"))
        case .row:
            return n.contains("row") && !n.contains("face")
        }
    }
}
