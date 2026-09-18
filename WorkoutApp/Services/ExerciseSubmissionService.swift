import Foundation
import SwiftData
import UIKit

struct CustomExerciseRecord: Identifiable, Hashable {
    let id: String
    let name: String
    let equipment: ExerciseEquipment
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let hasExplicitEquipment: Bool

    init(
        name: String,
        equipment: ExerciseEquipment,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        hasExplicitEquipment: Bool = false
    ) {
        self.id = name.lowercased()
        self.name = name
        self.equipment = equipment
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.hasExplicitEquipment = hasExplicitEquipment
    }
}

enum CustomExerciseCollector {
    static func collect(programs: [Program], sessions: [WorkoutSession]) -> [CustomExerciseRecord] {
        var byKey: [String: CustomExerciseRecord] = [:]

        for program in programs {
            for day in program.orderedDays {
                for exercise in day.orderedExercises where ExerciseCatalog.match(name: exercise.name) == nil {
                    merge(
                        &byKey,
                        CustomExerciseRecord(
                            name: exercise.name,
                            equipment: exercise.equipment,
                            primaryMuscles: exercise.primaryMuscles,
                            secondaryMuscles: exercise.secondaryMuscles,
                            hasExplicitEquipment: true
                        )
                    )
                }
            }
        }

        for session in sessions {
            for set in session.orderedSets where ExerciseCatalog.match(name: set.exerciseName) == nil {
                merge(
                    &byKey,
                    CustomExerciseRecord(
                        name: set.exerciseName,
                        equipment: ExerciseCatalog.equipment(forName: set.exerciseName),
                        primaryMuscles: set.primaryMuscles,
                        secondaryMuscles: set.secondaryMuscles
                    )
                )
            }
        }

        return byKey.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    static func delete(
        name: String,
        programs: [Program],
        sessions: [WorkoutSession],
        in modelContext: ModelContext
    ) {
        let key = name.lowercased()
        guard ExerciseCatalog.match(name: name) == nil else { return }

        for program in programs {
            for day in program.orderedDays {
                for exercise in day.exercises where exercise.name.lowercased() == key {
                    modelContext.delete(exercise)
                }
            }
        }

        for session in sessions {
            for set in session.sets where set.exerciseName.lowercased() == key {
                modelContext.delete(set)
            }
        }

        try? modelContext.save()
    }

    private static func merge(_ map: inout [String: CustomExerciseRecord], _ record: CustomExerciseRecord) {
        let key = record.id
        guard let existing = map[key] else {
            map[key] = record
            return
        }
        let preferred = existing.hasExplicitEquipment ? existing : record
        let fallback = existing.hasExplicitEquipment ? record : existing
        map[key] = CustomExerciseRecord(
            name: preferred.name,
            equipment: preferred.hasExplicitEquipment ? preferred.equipment : fallback.equipment,
            primaryMuscles: preferred.primaryMuscles.isEmpty ? fallback.primaryMuscles : preferred.primaryMuscles,
            secondaryMuscles: preferred.secondaryMuscles.isEmpty ? fallback.secondaryMuscles : preferred.secondaryMuscles,
            hasExplicitEquipment: existing.hasExplicitEquipment || record.hasExplicitEquipment
        )
    }
}

enum ExerciseSubmissionService {
    static let adminEmail = "octavian.mihai321@gmail.com"

    static func formattedBody(
        exercises: [CustomExerciseRecord],
        userNote: String? = nil
    ) -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        var bodyLines = [
            exercises.count == 1
                ? "New exercise submission from Workout app"
                : "Custom exercise submissions from Workout app (\(exercises.count))",
            ""
        ]

        for (index, exercise) in exercises.enumerated() {
            if exercises.count > 1 {
                bodyLines.append("--- Exercise \(index + 1) ---")
            }
            bodyLines.append("Name: \(exercise.name)")
            bodyLines.append("Equipment: \(exercise.equipment.displayTitle)")
            bodyLines.append("Primary muscles: \(exercise.primaryMuscles.joined(separator: ", "))")
            bodyLines.append(
                "Secondary muscles: \(exercise.secondaryMuscles.isEmpty ? "—" : exercise.secondaryMuscles.joined(separator: ", "))"
            )
            if index < exercises.count - 1 {
                bodyLines.append("")
            }
        }

        bodyLines.append("")
        bodyLines.append("App version: \(version) (\(build))")

        if let userNote, !userNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            bodyLines.append("")
            bodyLines.append("Note: \(userNote)")
        }

        return bodyLines.joined(separator: "\n")
    }

    static func mailtoURL(
        exerciseName: String,
        equipment: ExerciseEquipment,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        userNote: String? = nil
    ) -> URL? {
        mailtoURL(
            exercises: [
                CustomExerciseRecord(
                    name: exerciseName,
                    equipment: equipment,
                    primaryMuscles: primaryMuscles,
                    secondaryMuscles: secondaryMuscles
                )
            ],
            userNote: userNote
        )
    }

    static func mailtoURL(exercises: [CustomExerciseRecord], userNote: String? = nil) -> URL? {
        guard !exercises.isEmpty else { return nil }

        let subject: String
        if exercises.count == 1 {
            subject = "Exercise catalog request: \(exercises[0].name)"
        } else {
            subject = "Exercise catalog requests (\(exercises.count) exercises)"
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = adminEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: formattedBody(exercises: exercises, userNote: userNote))
        ]
        return components.url
    }

    @MainActor
    static func openMail(
        exerciseName: String,
        equipment: ExerciseEquipment,
        primaryMuscles: [String],
        secondaryMuscles: [String]
    ) -> Bool {
        openMail(
            exercises: [
                CustomExerciseRecord(
                    name: exerciseName,
                    equipment: equipment,
                    primaryMuscles: primaryMuscles,
                    secondaryMuscles: secondaryMuscles
                )
            ]
        )
    }

    @MainActor
    static func openMail(exercises: [CustomExerciseRecord]) -> Bool {
        guard let url = mailtoURL(exercises: exercises) else { return false }
        UIApplication.shared.open(url)
        return true
    }
}
