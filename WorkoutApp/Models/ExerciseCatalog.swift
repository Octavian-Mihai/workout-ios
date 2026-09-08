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

enum ExerciseEquipment: String, CaseIterable, Identifiable, Hashable, Codable {
    case barbell
    case machine
    case kettlebell
    case dumbbell
    case bodyweight

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .barbell: return "Barbell"
        case .machine: return "Machine"
        case .kettlebell: return "Kettlebell"
        case .dumbbell: return "Dumbbell"
        case .bodyweight: return "Bodyweight"
        }
    }

    var shortBadge: String {
        switch self {
        case .barbell: return "BB"
        case .machine: return "MC"
        case .kettlebell: return "KB"
        case .dumbbell: return "DB"
        case .bodyweight: return "BW"
        }
    }

    var showsPlateCalculator: Bool {
        self == .barbell || self == .machine
    }

    static func from(raw: String) -> ExerciseEquipment? {
        switch raw {
        case "functionalTrainer": return .machine
        case "other": return nil
        default: return ExerciseEquipment(rawValue: raw)
        }
    }

    static func resolve(raw: String?, name: String) -> ExerciseEquipment {
        if let raw, let resolved = from(raw: raw) {
            return resolved
        }
        return infer(from: name)
    }

    static func infer(from name: String) -> ExerciseEquipment {
        let n = name.lowercased()
        if n.contains("kettlebell") || n.contains("goblet") {
            return .kettlebell
        }
        if n.contains("dumbbell") {
            return .dumbbell
        }
        if n.contains("push-up") || n.contains("push up")
            || n.contains("pull-up") || n.contains("pull up")
            || n.contains("chin-up") || n.contains("chin up")
            || (n.contains("dip") && !n.contains("machine"))
            || n.contains("plank") || n.contains("bodyweight")
            || n.contains("pistol") || n.contains("ab wheel") {
            return .bodyweight
        }
        if n.contains("machine") || n.contains("leg press") || n.contains("leg extension")
            || n.contains("leg curl") || n.contains("calf raise")
            || n.contains("functional trainer") || n.contains("cable")
            || n.contains("lat pulldown") || n.contains("pulldown")
            || n.contains("face pull") || n.contains("pushdown") || n.contains("smith") {
            return .machine
        }
        if n.contains("barbell") || n.contains("deadlift") || n.contains("ohp")
            || n.contains("overhead press") || n.contains("hip thrust") || n.contains("bench")
            || n.contains("skull crusher") {
            return .barbell
        }
        if n.contains("squat"),
           !n.contains("split"),
           !n.contains("hack"),
           !n.contains("goblet"),
           !n.contains("pistol") {
            return .barbell
        }
        if n.contains("lunge") || n.contains("split squat") || n.contains("curl")
            || n.contains("raise") || n.contains("fly") {
            return .dumbbell
        }
        return .bodyweight
    }
}

struct CatalogExercise: Identifiable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let primary: [MuscleGroup]
    let secondary: [MuscleGroup]
    let cues: String
    let equipment: ExerciseEquipment
    let imageAssetName: String?

    var primaryNames: [String] { primary.map(\.rawValue) }
    var secondaryNames: [String] { secondary.map(\.rawValue) }

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        primary: [MuscleGroup],
        secondary: [MuscleGroup],
        cues: String,
        equipment: ExerciseEquipment? = nil,
        imageAssetName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.primary = primary
        self.secondary = secondary
        self.cues = cues
        self.equipment = equipment ?? ExerciseEquipment.infer(from: name)
        self.imageAssetName = imageAssetName
    }
}

enum ExerciseCatalog {
    static let all: [CatalogExercise] = [
        CatalogExercise(
            id: "back-squat",
            name: "Back Squat",
            category: .legs,
            primary: [.quads, .glutes],
            secondary: [.adductors, .core, .lowerBack],
            cues: "Brace before you descend. Sit between the hips, keep mid-foot pressure, and stand without collapsing the chest.",
            equipment: .barbell
        ),
        CatalogExercise(
            id: "front-squat",
            name: "Front Squat",
            category: .legs,
            primary: [.quads, .core],
            secondary: [.glutes, .upperBack],
            cues: "Elbows high, torso tall. The bar stays over mid-foot as you sit down and drive up.",
            equipment: .barbell
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
            cues: "Soft knees, push the hips back, bar close to the legs. Stop when the hamstrings run out of range.",
            equipment: .barbell
        ),
        CatalogExercise(
            id: "deadlift",
            name: "Deadlift",
            category: .pull,
            primary: [.hamstrings, .glutes, .lowerBack],
            secondary: [.quads, .traps, .lats, .core],
            cues: "Wedge in, brace, and push the floor away. The bar stays over mid-foot from floor to lockout.",
            equipment: .barbell
        ),
        CatalogExercise(
            id: "hip-thrust",
            name: "Hip Thrust",
            category: .legs,
            primary: [.glutes],
            secondary: [.hamstrings, .core],
            cues: "Chin tucked, ribs down. Finish with a hard glute squeeze and a flat torso at the top.",
            equipment: .barbell
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
            cues: "Plant the feet, set the scaps, and lower to the chest with wrists stacked. Press back toward the rack.",
            equipment: .barbell
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
            cues: "Glutes tight, ribs stacked. Bar path close to the face; head through at the top.",
            equipment: .barbell
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
            cues: "Soft elbows, sweep in an arc, and squeeze without shrugging.",
            equipment: .machine
        ),
        CatalogExercise(
            id: "tricep-pushdown",
            name: "Tricep Pushdown",
            category: .push,
            primary: [.triceps],
            secondary: [],
            cues: "Elbows pinned by the sides. Full extension, then a controlled return.",
            equipment: .machine
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
            cues: "Hinge, brace, and row to the lower ribs. Don’t turn it into a shrug or a deadlift.",
            equipment: .barbell
        ),
        CatalogExercise(
            id: "seated-cable-row",
            name: "Seated Cable Row",
            category: .pull,
            primary: [.lats, .upperBack],
            secondary: [.biceps, .rearDelts],
            cues: "Start from a long arm. Pull elbows back, pause, then reach forward without rounding hard.",
            equipment: .machine
        ),
        CatalogExercise(
            id: "lat-pulldown",
            name: "Lat Pulldown",
            category: .pull,
            primary: [.lats],
            secondary: [.biceps, .upperBack],
            cues: "Set the scaps first. Pull the bar to the upper chest, elbows down, not behind the body.",
            equipment: .machine
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
            cues: "Pull toward the face, externally rotate at the end, and keep the ribs down.",
            equipment: .machine
        ),
        CatalogExercise(
            id: "barbell-curl",
            name: "Barbell Curl",
            category: .pull,
            primary: [.biceps],
            secondary: [.forearms],
            cues: "Elbows close. No swing. Squeeze at the top and lower for 2–3 seconds.",
            equipment: .barbell
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
            cues: "Round the spine to shorten the abs. Hips stay relatively still.",
            equipment: .machine
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

    static func equipment(forName name: String) -> ExerciseEquipment {
        match(name: name)?.equipment ?? ExerciseEquipment.infer(from: name)
    }

    static func imageAssetName(for exercise: CatalogExercise) -> String {
        exercise.imageAssetName ?? "exercise-\(exercise.id)"
    }
}
