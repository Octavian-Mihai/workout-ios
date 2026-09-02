import Foundation

struct ProgramMuscleRow: Identifiable {
    var id: String { name }
    let name: String
    let region: String
    let exerciseCredit: Double
    let setCredit: Double

    func sortValue(usingSets: Bool) -> Double {
        usingSets ? setCredit : exerciseCredit
    }
}

struct ProgramRegionGroup: Identifiable {
    var id: String { name }
    let name: String
    let rows: [ProgramMuscleRow]
    let exerciseCredit: Double
    let setCredit: Double
}

struct ProgramOverviewSnapshot {
    let programName: String
    let dayCount: Int
    let exerciseCount: Int
    let plannedSets: Int
    let rows: [ProgramMuscleRow]
    let regionGroups: [ProgramRegionGroup]
    let insights: [String]

    var usesSetVolume: Bool { plannedSets > 0 }

    static func build(from program: Program) -> ProgramOverviewSnapshot {
        let exercises = program.orderedDays.flatMap(\.orderedExercises)
        return build(
            name: program.name,
            dayCount: program.orderedDays.count,
            exercises: exercises.map {
                PlannedLift(
                    primaryMuscles: $0.primaryMuscles,
                    secondaryMuscles: $0.secondaryMuscles,
                    targetSets: $0.targetSets
                )
            }
        )
    }

    static func build(name: String, dayCount: Int, exercises: [PlannedLift]) -> ProgramOverviewSnapshot {
        var exerciseCredit: [String: Double] = [:]
        var setCredit: [String: Double] = [:]

        for exercise in exercises {
            let primary = uniqueMuscles(exercise.primaryMuscles)
            let secondary = uniqueMuscles(exercise.secondaryMuscles).filter { !primary.contains($0) }
            let sets = Double(max(exercise.targetSets, 0))
            for muscle in primary {
                exerciseCredit[muscle, default: 0] += 1
                setCredit[muscle, default: 0] += sets
            }
            for muscle in secondary {
                exerciseCredit[muscle, default: 0] += 0.5
                setCredit[muscle, default: 0] += sets * 0.5
            }
        }

        let names = Set(exerciseCredit.keys).union(setCredit.keys)
        let usingSets = exercises.contains { $0.targetSets > 0 }
        let rows = names.map { muscle in
            ProgramMuscleRow(
                name: muscle,
                region: regionName(for: muscle),
                exerciseCredit: exerciseCredit[muscle] ?? 0,
                setCredit: setCredit[muscle] ?? 0
            )
        }
        .sorted { lhs, rhs in
            let l = lhs.sortValue(usingSets: usingSets)
            let r = rhs.sortValue(usingSets: usingSets)
            if l != r { return l > r }
            return lhs.name < rhs.name
        }

        let regionGroups = Dictionary(grouping: rows, by: \.region)
            .map { region, items in
                ProgramRegionGroup(
                    name: region,
                    rows: items,
                    exerciseCredit: items.reduce(0) { $0 + $1.exerciseCredit },
                    setCredit: items.reduce(0) { $0 + $1.setCredit }
                )
            }
            .sorted { lhs, rhs in
                let l = usingSets ? lhs.setCredit : lhs.exerciseCredit
                let r = usingSets ? rhs.setCredit : rhs.exerciseCredit
                if l != r { return l > r }
                return lhs.name < rhs.name
            }

        return ProgramOverviewSnapshot(
            programName: name,
            dayCount: dayCount,
            exerciseCount: exercises.count,
            plannedSets: exercises.reduce(0) { $0 + max($1.targetSets, 0) },
            rows: rows,
            regionGroups: regionGroups,
            insights: insights(rows: rows, exerciseCount: exercises.count, plannedSets: exercises.reduce(0) { $0 + max($1.targetSets, 0) })
        )
    }

    struct PlannedLift {
        let primaryMuscles: [String]
        let secondaryMuscles: [String]
        let targetSets: Int
    }
}

private extension ProgramOverviewSnapshot {
    static func uniqueMuscles(_ names: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in names {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(name).inserted else { continue }
            result.append(name)
        }
        return result
    }

    static func regionName(for muscle: String) -> String {
        MuscleGroup(rawValue: muscle)?.region ?? "Other"
    }

    static func insights(rows: [ProgramMuscleRow], exerciseCount: Int, plannedSets: Int) -> [String] {
        if exerciseCount == 0 {
            return ["No exercises in this rotation yet. Add days and lifts, then tap Done to see the split."]
        }

        var notes: [String] = []
        let usingSets = plannedSets > 0
        let byName = Dictionary(uniqueKeysWithValues: rows.map { ($0.name, $0) })

        func credit(_ muscles: [String]) -> Double {
            muscles.reduce(0) { sum, name in
                let row = byName[name]
                return sum + (usingSets ? (row?.setCredit ?? 0) : (row?.exerciseCredit ?? 0))
            }
        }

        func regionCredit(_ region: String) -> Double {
            rows.filter { $0.region == region }.reduce(0) {
                $0 + (usingSets ? $1.setCredit : $1.exerciseCredit)
            }
        }

        if !usingSets {
            notes.append("Target sets are still 0. Exercise counts are shown; set planned sets on each lift to see volume.")
        }

        let regionOrder = ["Upper body", "Arms", "Lower body", "Trunk"]
        let missing = regionOrder.filter { regionCredit($0) == 0 }
        let trained = regionOrder.filter { regionCredit($0) > 0 }

        for region in missing {
            switch region {
            case "Lower body":
                notes.append("No lower-body credit — quads, glutes, and hamstrings never appear as primary or secondary.")
            case "Upper body":
                notes.append("No upper-body work — chest, back, and delts are absent from the rotation.")
            case "Trunk":
                notes.append("Trunk is neglected. Core and lower back have no credit, even as secondary on compounds.")
            case "Arms":
                if trained.contains("Upper body") {
                    notes.append("No arm credit yet. Biceps and triceps aren’t tagged, even as secondary on presses or pulls.")
                }
            default:
                break
            }
        }

        let push = credit(["Chest", "Front Delts", "Side Delts", "Triceps"])
        let pull = credit(["Lats", "Upper Back", "Traps", "Rear Delts", "Biceps", "Forearms"])
        if push > 0 || pull > 0 {
            let heavier = max(push, pull)
            let lighter = min(push, pull)
            if heavier > 0, lighter < heavier * 0.6 {
                if push > pull {
                    notes.append("Pressing outweighs pulling. Add rows or pulldowns so the back keeps up with chest and delts.")
                } else {
                    notes.append("Pull volume is well ahead of pressing. The split leans toward rows and vertical pulls.")
                }
            }
        }

        let quads = credit(["Quads"])
        let posterior = credit(["Hamstrings", "Glutes"])
        if quads > 0 || posterior > 0 {
            if quads > posterior * 1.6 {
                notes.append("Quad-dominant lower body. Hinges are light next to squat patterns.")
            } else if posterior > quads * 1.6 {
                notes.append("Hinge-heavy lower body. Quads are light compared with hamstrings and glutes.")
            }
        }

        let frontPress = credit(["Chest", "Front Delts"])
        let rearSupport = credit(["Rear Delts", "Upper Back"])
        if frontPress > 0, rearSupport < frontPress * 0.45 {
            notes.append("Pressing is loaded relative to rear delts and upper back. Rows or face pulls would even the shoulder.")
        }

        if let top = rows.first, rows.count >= 2 {
            let total = rows.reduce(0) { $0 + $1.sortValue(usingSets: usingSets) }
            let second = rows[1].sortValue(usingSets: usingSets)
            let topValue = top.sortValue(usingSets: usingSets)
            if total > 0, topValue >= total * 0.32, topValue >= second * 1.8 {
                let unit = usingSets ? "set credit" : "exercise credit"
                notes.append("\(top.name) dominates the split with the largest share of \(unit).")
            }
        }

        if notes.isEmpty {
            if trained.count >= 3 {
                notes.append("Coverage spans \(listPhrase(trained)). Push/pull and lower-body credit are in the same ballpark.")
            } else if trained.count == 2 {
                notes.append("Work is concentrated in \(listPhrase(trained)).")
            } else if let only = trained.first {
                notes.append("This rotation is all \(only.lowercased()) — other regions never appear.")
            }
        }

        return Array(notes.prefix(4))
    }

    static func listPhrase(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0].lowercased()
        case 2: return "\(items[0].lowercased()) and \(items[1].lowercased())"
        default:
            let head = items.dropLast().map { $0.lowercased() }.joined(separator: ", ")
            return "\(head), and \(items.last?.lowercased() ?? "")"
        }
    }
}
