import SwiftUI

// MARK: - Data Models
struct MovementPattern: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: String
    let primaryMuscles: String
    let secondaryMuscles: String?
    let equipment: String
    let execution: String
    let tips: String
}

struct GuideMuscleGroup: Identifiable, Codable {
    let id = UUID()
    let name: String
    let function: String
    let exampleExercises: String
    let movementPatterns: [String] // references to pattern names
}

// MARK: - Data Store
class AnatomyStore: ObservableObject {
    @Published var movementPatterns: [MovementPattern] = []
    @Published var muscleGroups: [GuideMuscleGroup] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Build movement patterns from the provided lists (condensed into 6 core categories)
        movementPatterns = [
            MovementPattern(
                name: "Vertical Push",
                category: "PUSHES",
                primaryMuscles: "Deltoids (anterior & lateral), Triceps, Upper Pectoralis",
                secondaryMuscles: "Trapezius, Serratus Anterior",
                equipment: "Dumbbells, Barbell, Kettlebell",
                execution: "Press weight overhead from shoulders to full lockout. Control descent.",
                tips: "Keep core braced, avoid lumbar hyperextension."
            ),
            MovementPattern(
                name: "Horizontal Push",
                category: "PUSHES",
                primaryMuscles: "Pectoralis Major, Triceps, Anterior Deltoid",
                secondaryMuscles: "Serratus Anterior, Coracobrachialis",
                equipment: "Barbell, Dumbbells, Push-up bars",
                execution: "Press weight away from chest. Lower to sternum or mid-chest.",
                tips: "Retract scapulae, maintain neutral spine."
            ),
            MovementPattern(
                name: "Vertical Pull",
                category: "PULLS",
                primaryMuscles: "Latissimus Dorsi, Teres Major, Biceps",
                secondaryMuscles: "Posterior Deltoids, Rhomboids",
                equipment: "Pull-up bar, Lat pulldown, Rings",
                execution: "Pull weight down from overhead to chest or chin level.",
                tips: "Depress scapulae, drive elbows down."
            ),
            MovementPattern(
                name: "Horizontal Pull",
                category: "PULLS",
                primaryMuscles: "Rhomboids, Middle Trapezius, Posterior Deltoids, Biceps",
                secondaryMuscles: "Latissimus Dorsi, Teres Major",
                equipment: "Barbell, Dumbbells, Cable row, Meadows row",
                execution: "Pull weight toward torso while retracting scapulae.",
                tips: "Hold contraction at peak, avoid rounding lower back."
            ),
            MovementPattern(
                name: "Squat Pattern",
                category: "LEGS",
                primaryMuscles: "Quadriceps, Gluteus Maximus, Adductors",
                secondaryMuscles: "Erectors, Core, Calves",
                equipment: "Barbell, Safety Squat Bar, Goblet Dumbbell",
                execution: "Descend by pushing hips back and knees forward. Keep chest up.",
                tips: "Depth to parallel or below, drive through midfoot."
            ),
            MovementPattern(
                name: "Hinge Pattern",
                category: "LEGS",
                primaryMuscles: "Hamstrings, Gluteus Maximus, Erectors",
                secondaryMuscles: "Adductors, Core",
                equipment: "Barbell, Dumbbells, Kettlebell",
                execution: "Hinge at hips with minimal knee bend, back straight.",
                tips: "Push hips back, maintain neutral spine, feel hamstring stretch."
            ),
            MovementPattern(
                name: "Single-Leg Pattern",
                category: "LEGS",
                primaryMuscles: "Gluteus Medius, Quadriceps, Hamstrings, Calves",
                secondaryMuscles: "Core, Adductors",
                equipment: "Dumbbells, Kettlebell, TRX",
                execution: "Lunge, step-up, or single-leg deadlift. Maintain stability.",
                tips: "Knee tracking over toes, pelvis level."
            ),
            MovementPattern(
                name: "Anti-Rotation & Anti-Lateral",
                category: "ROTATIONAL CORE",
                primaryMuscles: "Obliques, Transverse Abdominis, Erector Spinae",
                secondaryMuscles: "Glutes, Lats",
                equipment: "Cable, Landmine, Kettlebell",
                execution: "Resist rotation or side-bending while moving load.",
                tips: "Brace core, keep ribs down, slow controlled reps."
            ),
            MovementPattern(
                name: "Rotational Acceleration",
                category: "ROTATIONAL CORE",
                primaryMuscles: "Obliques, Rectus Abdominis, Erector Spinae",
                secondaryMuscles: "Hip flexors, Lats",
                equipment: "Cable, Landmine, Med Ball",
                execution: "Explosively rotate torso from a stable stance.",
                tips: "Generate power from hips, rotate as a unit."
            ),
            MovementPattern(
                name: "Loaded Carries",
                category: "ATHLETIC TRANSFERS",
                primaryMuscles: "Core, Trapezius, Forearms, Glutes",
                secondaryMuscles: "Erectors, Quadratus Lumborum",
                equipment: "Kettlebells, Dumbbells, Suitcase handles",
                execution: "Walk with load in one or both hands, maintain upright posture.",
                tips: "Keep shoulders back, engage lats, breathe continuously."
            ),
            MovementPattern(
                name: "Power / Triple Extension",
                category: "ATHLETIC TRANSFERS",
                primaryMuscles: "Glutes, Quadriceps, Calves, Erector Spinae",
                secondaryMuscles: "Deltoids, Trapezius",
                equipment: "Barbell, Kettlebell, Med Ball",
                execution: "Explosive extension of hips, knees, and ankles against load.",
                tips: "Start with hips high, accelerate through mid-thigh."
            ),
            MovementPattern(
                name: "Deceleration / Catching",
                category: "ATHLETIC TRANSFERS",
                primaryMuscles: "Anterior Deltoids, Pectorals, Core, Quads",
                secondaryMuscles: "Biceps, Forearms",
                equipment: "Med Ball, Dumbbells (eccentric)",
                execution: "Absorb impact by yielding through hips and chest.",
                tips: "Stay braced, cushion force with soft elbows and knees."
            )
        ]
        
        // Build muscle groups from the "complete/minimalist" and "complete list" data
        muscleGroups = [
            GuideMuscleGroup(
                name: "Biceps",
                function: "Elbow flexion, supination. Long head contributes to shoulder flexion.",
                exampleExercises: "BB Curl, Hammer Curl, Preacher Curl, Reverse Curl",
                movementPatterns: ["Horizontal Pull", "Vertical Pull"]
            ),
            GuideMuscleGroup(
                name: "Triceps",
                function: "Elbow extension. Long head extends shoulder, lateral head stabilizes.",
                exampleExercises: "Pushdown, Skullcrusher, Diamond Push-up, Overhead Extension",
                movementPatterns: ["Vertical Push", "Horizontal Push"]
            ),
            GuideMuscleGroup(
                name: "Back (Lats, Rhomboids, Traps)",
                function: "Scapular retraction, depression, shoulder extension, adduction.",
                exampleExercises: "Pull-up, Row, Meadows Row, Seal Row, Face Pull",
                movementPatterns: ["Vertical Pull", "Horizontal Pull", "Loaded Carries"]
            ),
            GuideMuscleGroup(
                name: "Chest (Pectorals)",
                function: "Shoulder horizontal adduction, flexion, internal rotation.",
                exampleExercises: "Bench Press, Incline Press, DB Fly, Decline Fly",
                movementPatterns: ["Horizontal Push", "Deceleration / Catching"]
            ),
            GuideMuscleGroup(
                name: "Shoulders (Deltoids)",
                function: "Abduction, flexion, extension, rotation of arm.",
                exampleExercises: "OHP, Lateral Raise, Rear Delt Fly, Face Pull",
                movementPatterns: ["Vertical Push", "Horizontal Push", "Power / Triple Extension"]
            ),
            GuideMuscleGroup(
                name: "Core & Abs",
                function: "Spinal flexion, rotation, anti-extension, anti-rotation.",
                exampleExercises: "Cable Crunch, Dragon Fly, Russian Twist, Plank",
                movementPatterns: ["Anti-Rotation & Anti-Lateral", "Rotational Acceleration", "Loaded Carries"]
            ),
            GuideMuscleGroup(
                name: "Quadriceps",
                function: "Knee extension, hip flexion.",
                exampleExercises: "Squat, Leg Extension, Bulgarian Split Squat, Goblet Squat",
                movementPatterns: ["Squat Pattern", "Power / Triple Extension"]
            ),
            GuideMuscleGroup(
                name: "Hamstrings",
                function: "Knee flexion, hip extension.",
                exampleExercises: "Nordic Curl, RDL, Glute Ham Raise, Leg Curl",
                movementPatterns: ["Hinge Pattern", "Single-Leg Pattern"]
            ),
            GuideMuscleGroup(
                name: "Glutes",
                function: "Hip extension, abduction, external rotation.",
                exampleExercises: "Step-ups, Lunges, Hip Thrust, RDL",
                movementPatterns: ["Squat Pattern", "Hinge Pattern", "Power / Triple Extension"]
            ),
            GuideMuscleGroup(
                name: "Calves & Tibialis",
                function: "Plantarflexion (gastrocnemius/soleus), dorsiflexion (tibialis anterior).",
                exampleExercises: "Standing Calf Raise, Seated Calf Raise, Tibialis Raise",
                movementPatterns: ["Single-Leg Pattern", "Power / Triple Extension"]
            ),
            GuideMuscleGroup(
                name: "Forearms & Grip",
                function: "Wrist flexion, extension, pronation, supination.",
                exampleExercises: "Wrist Curl, Reverse Curl, Pronation/Supination Twists",
                movementPatterns: ["Loaded Carries", "Vertical Pull", "Horizontal Pull"]
            ),
            GuideMuscleGroup(
                name: "Adductors / Abductors",
                function: "Adduction (pull leg in), Abduction (push leg out), pelvic stability.",
                exampleExercises: "Copenhagen Adductor, Lateral Lunge, Cable Side Extension",
                movementPatterns: ["Squat Pattern", "Single-Leg Pattern", "Anti-Rotation & Anti-Lateral"]
            ),
            GuideMuscleGroup(
                name: "Hip Flexors",
                function: "Hip flexion, stabilizes pelvis.",
                exampleExercises: "Reverse Squat, Hanging Leg Raise, Reverse Lunge",
                movementPatterns: ["Single-Leg Pattern", "Power / Triple Extension"]
            )
        ]
    }
}

// MARK: - Main Tab View
struct YourGuideView: View {
    @StateObject private var store = AnatomyStore()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home / Overview
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Anatomy Gym Masterclass")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top)
                        
                        Text("Movement is the language of the human body. This masterclass integrates anatomy, biomechanics, and training to build a complete human.")
                            .font(.headline)
                            .padding(.vertical)
                        
                        Divider()
                        
                        // Quick overview of the "Big 7" categories
                        VStack(alignment: .leading, spacing: 16) {
                            Text("The 6 Core Movement Categories")
                                .font(.title2)
                                .bold()
                            
                            ForEach(["PUSHES", "PULLS", "LEGS", "ROTATIONAL CORE", "ATHLETIC TRANSFERS"], id: \.self) { category in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(category)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(store.movementPatterns.filter { $0.category == category }.count) patterns")
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical)
                        
                        Divider()
                        
                        // Muscle group snapshot
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Muscle Groups")
                                .font(.title2)
                                .bold()
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(store.muscleGroups.prefix(6)) { muscle in
                                        VStack(alignment: .leading) {
                                            Text(muscle.name)
                                                .font(.headline)
                                            Text(muscle.function.prefix(40) + "...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 140)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Masterclass")
            }
            .tabItem {
                Label("Overview", systemImage: "house")
            }
            .tag(0)
            
            // Movement Patterns List
            NavigationView {
                List {
                    ForEach(Array(Set(store.movementPatterns.map { $0.category })).sorted(), id: \.self) { category in
                        Section(header: Text(category)) {
                            ForEach(store.movementPatterns.filter { $0.category == category }) { pattern in
                                NavigationLink(destination: MovementDetailView(pattern: pattern)) {
                                    VStack(alignment: .leading) {
                                        Text(pattern.name)
                                            .font(.headline)
                                        Text("Primary: \(pattern.primaryMuscles)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Movement Patterns")
            }
            .tabItem {
                Label("Patterns", systemImage: "figure.walk")
            }
            .tag(1)
            
            // Muscle Groups List
            NavigationView {
                List(store.muscleGroups) { muscle in
                    NavigationLink(destination: MuscleDetailView(muscle: muscle, patterns: store.movementPatterns)) {
                        VStack(alignment: .leading) {
                            Text(muscle.name)
                                .font(.headline)
                            Text("\(muscle.exampleExercises)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Muscle Anatomy")
            }
            .tabItem {
                Label("Anatomy", systemImage: "heart")
            }
            .tag(2)
            
            // The "Complete List" condensed view
            NavigationView {
                List {
                    Section(header: Text("The Big 7 Primary Strength Patterns")) {
                        ForEach(["Vertical Push", "Horizontal Push", "Vertical Pull", "Horizontal Pull", "Squat Pattern", "Hinge Pattern", "Single-Leg Pattern"], id: \.self) { name in
                            if let pattern = store.movementPatterns.first(where: { $0.name == name }) {
                                NavigationLink(destination: MovementDetailView(pattern: pattern)) {
                                    Label(pattern.name, systemImage: "checkmark.circle")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Prehab 360: Joint Health")) {
                        ForEach(["Shoulder", "Hip", "Knee", "Elbow/Wrist", "Spine"], id: \.self) { joint in
                            Text(joint)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("Core Stability (Anti-Series)")) {
                        ForEach(["Anti-Extension", "Anti-Rotation", "Anti-Lateral Flexion", "Rotation (Acceleration)"], id: \.self) { corePattern in
                            Text(corePattern)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("Athletic & Neuromuscular")) {
                        ForEach(["Power / Triple Extension", "Loaded Carries", "Deceleration", "Sprinting", "Rotational Throwing"], id: \.self) { ath in
                            Text(ath)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Complete Checklist")
            }
            .tabItem {
                Label("Checklist", systemImage: "list.bullet.rectangle")
            }
            .tag(3)
        }
    }
}

// MARK: - Detail Views
struct MovementDetailView: View {
    let pattern: MovementPattern
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(pattern.name)
                    .font(.largeTitle)
                    .bold()
                
                HStack {
                    Image(systemName: "tag")
                    Text(pattern.category)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                Group {
                    Text("Primary Muscles")
                        .font(.headline)
                        .bold()
                    Text(pattern.primaryMuscles)
                        .padding(.leading)
                    
                    if let secondary = pattern.secondaryMuscles {
                        Text("Secondary Muscles")
                            .font(.headline)
                            .bold()
                        Text(secondary)
                            .padding(.leading)
                    }
                }
                
                Group {
                    Text("Equipment")
                        .font(.headline)
                        .bold()
                    Text(pattern.equipment)
                        .padding(.leading)
                }
                
                Group {
                    Text("Execution")
                        .font(.headline)
                        .bold()
                    Text(pattern.execution)
                        .padding(.leading)
                }
                
                Group {
                    Text("Tips")
                        .font(.headline)
                        .bold()
                    Text(pattern.tips)
                        .padding(.leading)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Pattern Detail")
    }
}

struct MuscleDetailView: View {
    let muscle: GuideMuscleGroup
    let patterns: [MovementPattern]
    
    var relatedPatterns: [MovementPattern] {
        patterns.filter { muscle.movementPatterns.contains($0.name) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(muscle.name)
                    .font(.largeTitle)
                    .bold()
                
                Text("Function")
                    .font(.headline)
                    .bold()
                Text(muscle.function)
                    .padding(.leading)
                
                Text("Example Exercises")
                    .font(.headline)
                    .bold()
                Text(muscle.exampleExercises)
                    .padding(.leading)
                
                if !relatedPatterns.isEmpty {
                    Text("Related Movement Patterns")
                        .font(.headline)
                        .bold()
                    
                    ForEach(relatedPatterns) { pattern in
                        NavigationLink(destination: MovementDetailView(pattern: pattern)) {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                Text(pattern.name)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Muscle Detail")
    }
}
