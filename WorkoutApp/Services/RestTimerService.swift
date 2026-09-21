import ActivityKit
import Foundation
import UserNotifications

enum RestTimerSettings {
    static let notificationsKey = "restTimerNotifications"
}

@MainActor
final class RestTimerService: ObservableObject {
    static let shared = RestTimerService()

    @Published private(set) var restEndDate: Date?
    @Published private(set) var restDuration: Int = 90
    @Published private(set) var exerciseName: String?

    private var activity: Activity<RestTimerAttributes>?
    private var didRequestNotificationPermission = false

    private init() {}

    var isRunning: Bool {
        guard let restEndDate else { return false }
        return restEndDate.timeIntervalSinceNow > 0
    }

    func remainingSeconds(now: Date = Date()) -> Int {
        guard let restEndDate else { return restDuration }
        return max(0, Int(restEndDate.timeIntervalSince(now).rounded(.up)))
    }

    func startRest(duration: Int, exerciseName: String?, sessionLabel: String) {
        restDuration = duration
        self.exerciseName = exerciseName
        restEndDate = Date().addingTimeInterval(TimeInterval(duration))
        scheduleNotification(for: restEndDate!, exerciseName: exerciseName)
        startOrUpdateLiveActivity(sessionLabel: sessionLabel, exerciseName: exerciseName ?? "Rest")
    }

    func resetRest() {
        restEndDate = nil
        exerciseName = nil
        cancelNotification()
        endLiveActivity()
    }

    func syncFromWallClock(now: Date = Date()) -> Bool {
        guard let restEndDate else { return false }
        if restEndDate.timeIntervalSince(now) <= 0 {
            self.restEndDate = nil
            cancelNotification()
            endLiveActivity()
            return true
        }
        updateLiveActivity(exerciseName: exerciseName ?? "Rest")
        return false
    }

    private var notificationsEnabled: Bool {
        UserDefaults.standard.object(forKey: RestTimerSettings.notificationsKey) as? Bool ?? true
    }

    private func scheduleNotification(for endDate: Date, exerciseName: String?) {
        guard notificationsEnabled else { return }

        Task {
            if !didRequestNotificationPermission {
                didRequestNotificationPermission = true
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            }

            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["rest-timer"])

            let content = UNMutableNotificationContent()
            content.title = "Rest complete"
            content.body = exerciseName.map { "Ready for \($0)" } ?? "Time for your next set"
            content.sound = .default

            let interval = endDate.timeIntervalSinceNow
            guard interval > 1 else { return }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }

    private func startOrUpdateLiveActivity(sessionLabel: String, exerciseName: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let restEndDate else { return }

        let state = RestTimerAttributes.ContentState(restEndDate: restEndDate, exerciseName: exerciseName)
        if let activity {
            Task { await activity.update(ActivityContent(state: state, staleDate: restEndDate)) }
            return
        }

        let attributes = RestTimerAttributes(sessionLabel: sessionLabel)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: restEndDate),
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    private func updateLiveActivity(exerciseName: String) {
        guard let restEndDate, let activity else { return }
        let state = RestTimerAttributes.ContentState(restEndDate: restEndDate, exerciseName: exerciseName)
        Task { await activity.update(ActivityContent(state: state, staleDate: restEndDate)) }
    }

    private func endLiveActivity() {
        guard let activity else { return }
        let finalState = RestTimerAttributes.ContentState(
            restEndDate: Date(),
            exerciseName: exerciseName ?? "Rest"
        )
        Task {
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}

enum ExerciseRestDefaults {
    static func seconds(for exercise: DraftExercise, fallback: Int) -> Int {
        if let override = exercise.restSeconds { return override }
        if exercise.equipment == .barbell, exercise.primaryMuscles.count >= 2 {
            return 180
        }
        if exercise.primaryMuscles.count <= 1, exercise.equipment != .barbell {
            return 90
        }
        return fallback
    }

    static func seconds(for exercise: DayExercise, fallback: Int) -> Int {
        if let override = exercise.restSeconds { return override }
        if exercise.equipment == .barbell, exercise.primaryMuscles.count >= 2 {
            return 180
        }
        if exercise.primaryMuscles.count <= 1, exercise.equipment != .barbell {
            return 90
        }
        return fallback
    }
}
