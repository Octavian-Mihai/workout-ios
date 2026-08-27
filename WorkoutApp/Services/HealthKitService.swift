import Foundation
import HealthKit

struct RunningWorkout: Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let duration: TimeInterval
    let distanceMeters: Double
    let averageHeartRate: Double?

    var distanceKilometers: Double { distanceMeters / 1000.0 }

    var paceMinPerKm: Double? {
        guard distanceKilometers > 0, duration > 0 else { return nil }
        return (duration / 60.0) / distanceKilometers
    }

    var stress: Double {
        StressCalculator.runStress(
            duration: duration,
            distanceMeters: distanceMeters,
            averageHeartRate: averageHeartRate
        )
    }
}

@MainActor
final class HealthKitService: ObservableObject {
    @Published var isAuthorized = false
    @Published var runs: [RunningWorkout] = []
    @Published var lastError: String?
    @Published var isLoading = false

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAndLoad() async {
        guard isAvailable else {
            lastError = "Health data is not available on this device."
            return
        }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            try await requestAuthorization()
            isAuthorized = true
            try await loadRuns()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func requestAuthorization() async throws {
        guard let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitServiceError.missingTypes
        }

        let read: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            distance,
            heartRate
        ]
        try await store.requestAuthorization(toShare: Set<HKSampleType>(), read: read)
    }

    func loadRuns(limit: Int = 50) async throws {
        let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForWorkouts(with: .running)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
        runs = workouts.map { workout in
            let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
            return RunningWorkout(
                id: workout.uuid,
                start: workout.startDate,
                end: workout.endDate,
                duration: workout.duration,
                distanceMeters: distance,
                averageHeartRate: averageHeartRate(from: workout)
            )
        }
    }

    private func averageHeartRate(from workout: HKWorkout) -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let stats = workout.statistics(for: hrType)
        return stats?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }
}

enum HealthKitServiceError: LocalizedError {
    case missingTypes

    var errorDescription: String? {
        "Could not read running types from Health."
    }
}
