import Foundation

enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case chest = "Chest"
    case lats = "Lats"
    case upperBack = "Upper Back"
    case traps = "Traps"
    case frontDelts = "Front Delts"
    case sideDelts = "Side Delts"
    case rearDelts = "Rear Delts"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case adductors = "Adductors"
    case core = "Core"
    case lowerBack = "Lower Back"

    var id: String { rawValue }

    var region: String {
        switch self {
        case .chest, .lats, .upperBack, .traps, .frontDelts, .sideDelts, .rearDelts:
            return "Upper body"
        case .biceps, .triceps, .forearms:
            return "Arms"
        case .quads, .hamstrings, .glutes, .calves, .adductors:
            return "Lower body"
        case .core, .lowerBack:
            return "Trunk"
        }
    }
}

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
    case core = "Core"

    var id: String { rawValue }
}

struct CatalogExercise: Identifiable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let primary: [MuscleGroup]
    let secondary: [MuscleGroup]
    let cues: String

    var primaryNames: [String] { primary.map(\.rawValue) }
    var secondaryNames: [String] { secondary.map(\.rawValue) }
}

enum ExerciseCatalog {
    static let all: [CatalogExercise] = [
        CatalogExercise(
            id: "back-squat",
            name: "Back Squat",
            category: .legs,
            primary: [.quads, .glutes],
            secondary: [.adductors, .core, .lowerBack],
            cues: "Brace before you descend. Sit between the hips, keep mid-foot pressure, and stand without collapsing the chest."
        ),
        CatalogExercise(
            id: "front-squat",
            name: "Front Squat",
            category: .legs,
            primary: [.quads, .core],
            secondary: [.glutes, .upperBack],
            cues: "Elbows high, torso tall. The bar stays over mid-foot as you sit down and drive up."
        ),
        CatalogExercise(
            id: "leg-press",
            name: "Leg Press",
            category: .legs,
            primary: [.quads, .glutes],
            secondary: [.hamstrings, .adductors],
            cues: "Full foot on the platform. Lower with control and stop before the low back rounds."
        ),
        CatalogExercise(
            id: "bulgarian-split-squat",
            name: "Bulgarian Split Squat",
            category: .legs,
            primary: [.quads, .glutes],
            secondary: [.adductors, .core],
            cues: "Most of the load on the front leg. Slight forward lean is fine; keep the front knee tracking over the toes."
        ),
        CatalogExercise(
            id: "walking-lunge",
            name: "Walking Lunge",
            category: .legs,
            primary: [.quads, .glutes],
            secondary: [.hamstrings, .core],
            cues: "Long enough stride to load the glute. Front knee tracks the toes; trail knee drops under the hip."
        ),
        CatalogExercise(
            id: "leg-extension",
            name: "Leg Extension",
            category: .legs,
            primary: [.quads],
            secondary: [],
            cues: "Control the top squeeze. Avoid slamming the stack; pause briefly at lockout."
        ),
        CatalogExercise(
            id: "leg-curl",
            name: "Leg Curl",
            category: .legs,
            primary: [.hamstrings],
            secondary: [.calves],
            cues: "Hips stay pinned. Curl through a full range and lower slowly."
        ),
        CatalogExercise(
            id: "romanian-deadlift",
            name: "Romanian Deadlift",
            category: .legs,
            primary: [.hamstrings, .glutes],
            secondary: [.lowerBack, .traps],
            cues: "Soft knees, push the hips back, bar close to the legs. Stop when the hamstrings run out of range."
        ),
        CatalogExercise(
            id: "deadlift",
            name: "Deadlift",
            category: .pull,
            primary: [.hamstrings, .glutes, .lowerBack],
            secondary: [.quads, .traps, .lats, .core],
            cues: "Wedge in, brace, and push the floor away. The bar stays over mid-foot from floor to lockout."
        ),
        CatalogExercise(
            id: "hip-thrust",
            name: "Hip Thrust",
            category: .legs,
            primary: [.glutes],
            secondary: [.hamstrings, .core],
            cues: "Chin tucked, ribs down. Finish with a hard glute squeeze and a flat torso at the top."
        ),
        CatalogExercise(
            id: "calf-raise",
            name: "Calf Raise",
            category: .legs,
            primary: [.calves],
            secondary: [],
            cues: "Full stretch at the bottom, pause at the top. Knee position stays consistent."
        ),
        CatalogExercise(
            id: "barbell-bench-press",
            name: "Barbell Bench Press",
            category: .push,
            primary: [.chest],
            secondary: [.triceps, .frontDelts],
            cues: "Plant the feet, set the scaps, and lower to the chest with wrists stacked. Press back toward the rack."
        ),
        CatalogExercise(
            id: "incline-dumbbell-press",
            name: "Incline Dumbbell Press",
            category: .push,
            primary: [.chest, .frontDelts],
            secondary: [.triceps],
            cues: "30–45° bench. Lower until the elbows are in line with the torso, then press without flaring wildly."
        ),
        CatalogExercise(
            id: "dumbbell-bench-press",
            name: "Dumbbell Bench Press",
            category: .push,
            primary: [.chest],
            secondary: [.triceps, .frontDelts],
            cues: "Slight arch, dumbbells travel in a gentle arc. Control the bottom stretch."
        ),
        CatalogExercise(
            id: "dips",
            name: "Dips",
            category: .push,
            primary: [.chest, .triceps],
            secondary: [.frontDelts],
            cues: "Shoulders down. Lean forward for more chest; stay more upright for triceps. Don’t dump into the joints."
        ),
        CatalogExercise(
            id: "push-up",
            name: "Push-Up",
            category: .push,
            primary: [.chest],
            secondary: [.triceps, .frontDelts, .core],
            cues: "Body in one line. Elbows ~45° from the torso. Chest to near the floor, then press the floor away."
        ),
        CatalogExercise(
            id: "overhead-press",
            name: "Overhead Press",
            category: .push,
            primary: [.frontDelts],
            secondary: [.triceps, .traps, .core],
            cues: "Glutes tight, ribs stacked. Bar path close to the face; head through at the top."
        ),
        CatalogExercise(
            id: "dumbbell-shoulder-press",
            name: "Dumbbell Shoulder Press",
            category: .push,
            primary: [.frontDelts, .sideDelts],
            secondary: [.triceps],
            cues: "Press slightly in front of the head. Don’t over-arch the low back."
        ),
        CatalogExercise(
            id: "lateral-raise",
            name: "Lateral Raise",
            category: .push,
            primary: [.sideDelts],
            secondary: [.traps],
            cues: "Lead with the elbows, slight lean, and stop around shoulder height. Control the lower."
        ),
        CatalogExercise(
            id: "cable-fly",
            name: "Cable Fly",
            category: .push,
            primary: [.chest],
            secondary: [.frontDelts],
            cues: "Soft elbows, sweep in an arc, and squeeze without shrugging."
        ),
        CatalogExercise(
            id: "tricep-pushdown",
            name: "Tricep Pushdown",
            category: .push,
            primary: [.triceps],
            secondary: [],
            cues: "Elbows pinned by the sides. Full extension, then a controlled return."
        ),
        CatalogExercise(
            id: "skull-crusher",
            name: "Skull Crusher",
            category: .push,
            primary: [.triceps],
            secondary: [],
            cues: "Only the elbows move. Lower toward the forehead or hairline, then extend without flaring."
        ),
        CatalogExercise(
            id: "barbell-row",
            name: "Barbell Row",
            category: .pull,
            primary: [.lats, .upperBack],
            secondary: [.biceps, .rearDelts, .lowerBack],
            cues: "Hinge, brace, and row to the lower ribs. Don’t turn it into a shrug or a deadlift."
        ),
        CatalogExercise(
            id: "seated-cable-row",
            name: "Seated Cable Row",
            category: .pull,
            primary: [.lats, .upperBack],
            secondary: [.biceps, .rearDelts],
            cues: "Start from a long arm. Pull elbows back, pause, then reach forward without rounding hard."
        ),
        CatalogExercise(
            id: "lat-pulldown",
            name: "Lat Pulldown",
            category: .pull,
            primary: [.lats],
            secondary: [.biceps, .upperBack],
            cues: "Set the scaps first. Pull the bar to the upper chest, elbows down, not behind the body."
        ),
        CatalogExercise(
            id: "pull-up",
            name: "Pull-Up",
            category: .pull,
            primary: [.lats],
            secondary: [.biceps, .upperBack],
            cues: "Dead hang to chin over the bar. Drive elbows down; avoid kipping unless that’s the point."
        ),
        CatalogExercise(
            id: "chin-up",
            name: "Chin-Up",
            category: .pull,
            primary: [.lats, .biceps],
            secondary: [.upperBack],
            cues: "Supinated grip. Same full range as a pull-up, with a little more biceps."
        ),
        CatalogExercise(
            id: "face-pull",
            name: "Face Pull",
            category: .pull,
            primary: [.rearDelts, .traps],
            secondary: [.upperBack],
            cues: "Pull toward the face, externally rotate at the end, and keep the ribs down."
        ),
        CatalogExercise(
            id: "barbell-curl",
            name: "Barbell Curl",
            category: .pull,
            primary: [.biceps],
            secondary: [.forearms],
            cues: "Elbows close. No swing. Squeeze at the top and lower for 2–3 seconds."
        ),
        CatalogExercise(
            id: "dumbbell-curl",
            name: "Dumbbell Curl",
            category: .pull,
            primary: [.biceps],
            secondary: [.forearms],
            cues: "Supinate through the lift. Keep the upper arm still."
        ),
        CatalogExercise(
            id: "hammer-curl",
            name: "Hammer Curl",
            category: .pull,
            primary: [.biceps, .forearms],
            secondary: [],
            cues: "Neutral grip. Control both directions; this is also a forearm builder."
        ),
        CatalogExercise(
            id: "plank",
            name: "Plank",
            category: .core,
            primary: [.core],
            secondary: [.frontDelts, .glutes],
            cues: "Ribs down, glutes on, neck long. Don’t sag or pike."
        ),
        CatalogExercise(
            id: "hanging-leg-raise",
            name: "Hanging Leg Raise",
            category: .core,
            primary: [.core],
            secondary: [.forearms],
            cues: "Posteriorly tilt the pelvis and lift with the abs, not momentum."
        ),
        CatalogExercise(
            id: "cable-crunch",
            name: "Cable Crunch",
            category: .core,
            primary: [.core],
            secondary: [],
            cues: "Round the spine to shorten the abs. Hips stay relatively still."
        ),
        CatalogExercise(
            id: "ab-wheel",
            name: "Ab Wheel",
            category: .core,
            primary: [.core],
            secondary: [.lats, .frontDelts],
            cues: "Roll out only as far as you can keep a braced, slightly rounded torso."
        )
    ]

    static func grouped() -> [(ExerciseCategory, [CatalogExercise])] {
        ExerciseCategory.allCases.compactMap { category in
            let items = all.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    static func match(name: String) -> CatalogExercise? {
        let key = name.lowercased()
        return all.first { $0.name.lowercased() == key }
    }
}
