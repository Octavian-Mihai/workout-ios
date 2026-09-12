import Foundation
import UIKit

enum ExerciseSubmissionService {
    static let adminEmail = "octavian.mihai321@gmail.com"

    static func mailtoURL(
        exerciseName: String,
        equipment: ExerciseEquipment,
        primaryMuscles: [String],
        secondaryMuscles: [String],
        userNote: String? = nil
    ) -> URL? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        var bodyLines = [
            "New exercise submission from Workout app",
            "",
            "Name: \(exerciseName)",
            "Equipment: \(equipment.displayTitle)",
            "Primary muscles: \(primaryMuscles.joined(separator: ", "))",
            "Secondary muscles: \(secondaryMuscles.isEmpty ? "—" : secondaryMuscles.joined(separator: ", "))",
            "App version: \(version) (\(build))"
        ]
        if let userNote, !userNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            bodyLines.append("")
            bodyLines.append("Note: \(userNote)")
        }

        let subject = "Exercise catalog request: \(exerciseName)"
        let body = bodyLines.joined(separator: "\n")

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = adminEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
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
        guard let url = mailtoURL(
            exerciseName: exerciseName,
            equipment: equipment,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles
        ) else {
            return false
        }
        UIApplication.shared.open(url)
        return true
    }
}
