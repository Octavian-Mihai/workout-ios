import Foundation

enum StressBand: String {
    case recovery = "Recovery / easy"
    case productive = "Productive"
    case high = "High — watch sleep/fatigue"
    case veryHigh = "Very high — consider backing off"

    var rangeLabel: String {
        switch self {
        case .recovery: return "0–30"
        case .productive: return "31–55"
        case .high: return "56–75"
        case .veryHigh: return "76–100"
        }
    }

    static func band(for score: Double) -> StressBand {
        switch score {
        case ..<30.5: return .recovery
        case ..<55.5: return .productive
        case ..<75.5: return .high
        default: return .veryHigh
        }
    }
}

enum StressCalculator {
    static let windowDays: Double = 7

    static func band(for score: Double) -> StressBand {
        StressBand.band(for: score)
    }

    static func setVolume(_ set: SetLog) -> Double {
        set.weight * Double(set.reps)
    }

    /// Primary muscles get full volume; secondary muscles get half.
    static func muscleVolume(from sets: [SetLog]) -> [String: Double] {
        var result: [String: Double] = [:]
        for set in sets {
            let vol = setVolume(set)
            for muscle in set.primaryMuscles {
                result[muscle, default: 0] += vol
            }
            for muscle in set.secondaryMuscles {
                result[muscle, default: 0] += vol * 0.5
            }
        }
        return result
    }

    static func totalVolume(from sets: [SetLog]) -> Double {
        sets.reduce(0) { $0 + setVolume($1) }
    }

    static func sets(inLastDays days: Double, from sets: [SetLog], now: Date = Date()) -> [SetLog] {
        let cutoff = now.addingTimeInterval(-days * 86_400)
        return sets.filter { $0.timestamp >= cutoff }
    }

    /// Central stress 0–100 from the last 7 days: heavy compounds, high % of est. 1RM, low RIR.
    /// Normalized so roughly 12 hard compound sets in a week sit near 100.
    static func centralStress(sets: [SetLog], now: Date = Date()) -> Double {
        let recent = self.sets(inLastDays: windowDays, from: sets, now: now).filter { isCompound($0.exerciseName) }
        guard !recent.isEmpty else { return 0 }

        var points = 0.0
        for set in recent {
            let best = bestEstimated1RM(for: set.exerciseName, in: sets, now: now)
            let pct1RM: Double
            if best > 0 {
                pct1RM = min(set.weight / best, 1.20)
            } else {
                pct1RM = 0.65
            }
            let rirScore = max(0, 5.0 - Double(min(set.rir, 5))) / 5.0
            let repFactor = min(Double(set.reps), 12.0) / 6.0
            points += (0.60 * pct1RM + 0.40 * rirScore) * repFactor
        }
        return min(100, (points / 12.0) * 100.0)
    }

    /// Total stress 0–100 from the last 7 days: volume load + intensity + optional run stress.
    static func totalStress(sets: [SetLog], runStress: Double = 0, now: Date = Date()) -> Double {
        let recent = self.sets(inLastDays: windowDays, from: sets, now: now)
        let volume = totalVolume(from: recent)
        let volumeScore = min(50.0, volume / 500.0)

        let intensities = recent.map { max(0, 5.0 - Double(min($0.rir, 5))) / 5.0 }
        let avgIntensity = intensities.isEmpty ? 0 : intensities.reduce(0, +) / Double(intensities.count)
        let intensityScore = avgIntensity * 30.0

        let runContribution = min(20.0, max(0, runStress) * 0.20)
        return min(100, volumeScore + intensityScore + runContribution)
    }

    /// Recovery complementary score: 100 − total stress.
    static func recoveryScore(totalStress: Double) -> Double {
        max(0, 100 - totalStress)
    }

    /// Run stress 0–100.
    /// HR path: Banister-style TRIMP from duration × HR reserve.
    /// No HR: duration × relative intensity vs an easy 8:00/km baseline.
    static func runStress(
        duration: TimeInterval,
        distanceMeters: Double,
        averageHeartRate: Double?,
        restingHeartRate: Double = 60,
        maxHeartRate: Double = 190
    ) -> Double {
        let minutes = max(duration / 60.0, 0)
        if let hr = averageHeartRate, hr > 0, maxHeartRate > restingHeartRate {
            let hrr = min(max((hr - restingHeartRate) / (maxHeartRate - restingHeartRate), 0), 1.05)
            let trimp = minutes * hrr * 0.64 * exp(1.92 * hrr)
            return min(100, trimp / 1.5)
        }

        let km = distanceMeters / 1000.0
        guard km > 0, minutes > 0 else {
            return min(100, minutes / 60.0 * 40.0)
        }
        let paceMinPerKm = minutes / km
        let easyPace = 8.0
        let relative = min(easyPace / max(paceMinPerKm, 3.0), 2.0)
        return min(100, (minutes / 60.0) * relative * 70.0)
    }

    static func averageRunStress(_ runs: [RunningWorkout], now: Date = Date()) -> Double {
        let cutoff = now.addingTimeInterval(-windowDays * 86_400)
        let recent = runs.filter { $0.start >= cutoff }
        guard !recent.isEmpty else { return 0 }
        let mean = recent.map(\.stress).reduce(0, +) / Double(recent.count)
        return min(100, mean)
    }

    static func isCompound(_ name: String) -> Bool {
        let n = name.lowercased()
        let keys = [
            "squat", "bench", "deadlift", "overhead press", "ohp",
            "military press", "barbell row", "pendlay", "pull-up", "pull up",
            "chin-up", "chin up", "dip"
        ]
        return keys.contains { n.contains($0) }
    }

    static func bestEstimated1RM(for exerciseName: String, in sets: [SetLog], now: Date = Date()) -> Double {
        let cutoff = now.addingTimeInterval(-90 * 86_400)
        let family = BigLift.allCases.first { $0.matches(exerciseName) }
        let candidates = sets.filter { set in
            guard set.timestamp >= cutoff, set.weight > 0, set.reps > 0 else { return false }
            if let family {
                return family.matches(set.exerciseName)
            }
            return set.exerciseName.compare(exerciseName, options: .caseInsensitive) == .orderedSame
        }
        return candidates.map { OneRM.estimate(weight: $0.weight, reps: $0.reps, rir: $0.rir) }.max() ?? 0
    }
}
