import Foundation
import HealthKit
import CoreLocation

struct RunningWorkout: Identifiable {
    let id: UUID
    let start: Date
    let end: Date
    let duration: TimeInterval
    let distanceMeters: Double
    let averageHeartRate: Double?
    let workout: HKWorkout

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

struct HeartRateSample: Identifiable {
    let date: Date
    let bpm: Double
    var id: Date { date }
}

struct PaceSample: Identifiable {
    let date: Date
    let minutesPerKm: Double
    var id: Date { date }
}

struct RunRoutePoint: Identifiable {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    var id: Date { timestamp }
}

struct RunDetailData {
    var heartRate: [HeartRateSample]
    var pace: [PaceSample]
    var route: [CLLocation]
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
            heartRate,
            HKSeriesType.workoutRoute()
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
                averageHeartRate: averageHeartRate(from: workout),
                workout: workout
            )
        }
    }

    func loadDetails(for run: RunningWorkout) async -> RunDetailData {
        async let heart = heartRateSeries(for: run.workout)
        async let distance = distanceSeries(for: run.workout)
        async let route = routeLocations(for: run.workout)
        let (hr, dist, locations) = await (heart, distance, route)
        return RunDetailData(
            heartRate: hr,
            pace: paceSeries(from: dist),
            route: locations
        )
    }

    private func averageHeartRate(from workout: HKWorkout) -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let stats = workout.statistics(for: hrType)
        return stats?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }

    private func heartRateSeries(for workout: HKWorkout) async -> [HeartRateSample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let samples = await quantitySamples(type: type, workout: workout)
        return samples.compactMap { sample in
            guard let quantity = sample as? HKQuantitySample else { return nil }
            return HeartRateSample(date: quantity.startDate, bpm: quantity.quantity.doubleValue(for: unit))
        }
    }

    private func distanceSeries(for workout: HKWorkout) async -> [(Date, Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return [] }
        let samples = await quantitySamples(type: type, workout: workout)
        return samples.compactMap { sample in
            guard let quantity = sample as? HKQuantitySample else { return nil }
            return (quantity.endDate, quantity.quantity.doubleValue(for: .meter()))
        }
    }

    private func paceSeries(from distanceSamples: [(Date, Double)]) -> [PaceSample] {
        guard distanceSamples.count >= 2 else { return [] }
        var points: [PaceSample] = []
        var cumulative = 0.0
        var previousDate: Date?
        var previousCumulative = 0.0
        let looksIncremental = distanceSamples.allSatisfy { $0.1 < 2000 } && (distanceSamples.last?.1 ?? 0) < 50_000

        for (date, meters) in distanceSamples {
            if looksIncremental {
                cumulative += meters
            } else {
                cumulative = meters
            }
            if let previousDate {
                let dt = date.timeIntervalSince(previousDate)
                let dd = cumulative - previousCumulative
                if dt > 0, dd > 0 {
                    let minPerKm = (dt / 60.0) / (dd / 1000.0)
                    if minPerKm.isFinite, minPerKm > 2, minPerKm < 20 {
                        points.append(PaceSample(date: date, minutesPerKm: minPerKm))
                    }
                }
            }
            previousDate = date
            previousCumulative = cumulative
        }
        return points
    }

    private func quantitySamples(type: HKQuantityType, workout: HKWorkout) async -> [HKSample] {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }

    private func routeLocations(for workout: HKWorkout) async -> [CLLocation] {
        let routes: [HKWorkoutRoute] = await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForObjects(from: workout)
            let query = HKSampleQuery(
                sampleType: HKSeriesType.workoutRoute(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkoutRoute]) ?? [])
            }
            store.execute(query)
        }
        guard let route = routes.first else { return [] }

        return await withCheckedContinuation { continuation in
            var all: [CLLocation] = []
            var finished = false
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if error != nil {
                    if !finished {
                        finished = true
                        continuation.resume(returning: all)
                    }
                    return
                }
                if let locations {
                    all.append(contentsOf: locations)
                }
                if done, !finished {
                    finished = true
                    continuation.resume(returning: all)
                }
            }
            store.execute(query)
        }
    }
}

enum HealthKitServiceError: LocalizedError {
    case missingTypes

    var errorDescription: String? {
        "Could not read running types from Health."
    }
}
