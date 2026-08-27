import SwiftUI
import Charts
import MapKit
import CoreLocation

struct RunningFilters: Equatable {
    var useMinDistance = false
    var useMaxDistance = false
    var minDistance: Double = 3
    var maxDistance: Double = 20
    var useMinDuration = false
    var useMaxDuration = false
    var minDurationMinutes: Double = 20
    var maxDurationMinutes: Double = 90
    var useMinPace = false
    var useMaxPace = false
    var minPace: Double = 4
    var maxPace: Double = 8
    var useStartDate = false
    var useEndDate = false
    var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var endDate = Date()

    var isActive: Bool {
        useMinDistance || useMaxDistance || useMinDuration || useMaxDuration
            || useMinPace || useMaxPace || useStartDate || useEndDate
    }

    func matches(_ run: RunningWorkout, unit: DistanceUnit) -> Bool {
        let distance = unit.fromMeters(run.distanceMeters)
        if useMinDistance, distance < minDistance { return false }
        if useMaxDistance, distance > maxDistance { return false }

        let minutes = run.duration / 60.0
        if useMinDuration, minutes < minDurationMinutes { return false }
        if useMaxDuration, minutes > maxDurationMinutes { return false }

        if let pace = unit.paceMinutesPerUnit(duration: run.duration, meters: run.distanceMeters) {
            if useMinPace, pace < minPace { return false }
            if useMaxPace, pace > maxPace { return false }
        } else if useMinPace || useMaxPace {
            return false
        }

        if useStartDate, run.start < Calendar.current.startOfDay(for: startDate) { return false }
        if useEndDate {
            let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
            if run.start >= end { return false }
        }
        return true
    }
}

struct RunningView: View {
    @EnvironmentObject private var health: HealthKitService
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue
    @AppStorage("distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @State private var filters = RunningFilters()
    @State private var showFilters = false

    private var accent: Color {
        AccentOption(rawValue: accentName)?.color ?? .orange
    }

    private var unit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .km
    }

    private var filtered: [RunningWorkout] {
        health.runs.filter { filters.matches($0, unit: unit) }
    }

    private var twoWeekCutoff: Date {
        Date().addingTimeInterval(-14 * 86_400)
    }

    private var recentRuns: [RunningWorkout] {
        filtered.filter { $0.start >= twoWeekCutoff }
    }

    private var olderRuns: [RunningWorkout] {
        filtered.filter { $0.start < twoWeekCutoff }
    }

    private var last7: [RunningWorkout] {
        let cutoff = Date().addingTimeInterval(-7 * 86_400)
        return health.runs.filter { $0.start >= cutoff }
    }

    private var avgPace: Double? {
        let paces = last7.compactMap { unit.paceMinutesPerUnit(duration: $0.duration, meters: $0.distanceMeters) }
        guard !paces.isEmpty else { return nil }
        return paces.reduce(0, +) / Double(paces.count)
    }

    private var bestPace: Double? {
        last7.compactMap { unit.paceMinutesPerUnit(duration: $0.duration, meters: $0.distanceMeters) }.min()
    }

    private var weeklyRunStress: Double {
        StressCalculator.averageRunStress(health.runs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !health.isAvailable {
                        Text("Health data is not available on this device.")
                            .padding(16)
                            .opaqueCard()
                    } else if let error = health.lastError {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error)
                                .font(.subheadline)
                            Button("Try again") {
                                Task { await health.requestAndLoad() }
                            }
                        }
                        .padding(16)
                        .opaqueCard()
                    }

                    analyticsCard

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent runs")
                                .font(.headline)
                            Spacer()
                            if filters.isActive {
                                Text("Filtered")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(accent)
                            }
                        }
                        if health.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if filtered.isEmpty {
                            Text(health.runs.isEmpty
                                 ? "No running workouts found in Apple Health. Record a run in the Fitness or Health app, then pull to refresh."
                                 : "No runs match these filters.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(16)
                                .opaqueCard()
                        } else {
                            ForEach(recentRuns) { run in
                                NavigationLink {
                                    RunDetailView(run: run, accent: accent, unit: unit)
                                        .environmentObject(health)
                                } label: {
                                    RunRow(run: run, accent: accent, unit: unit)
                                }
                                .buttonStyle(.plain)
                            }
                            if !olderRuns.isEmpty {
                                DisclosureGroup("Older than 2 weeks (\(olderRuns.count))") {
                                    VStack(spacing: 8) {
                                        ForEach(olderRuns) { run in
                                            NavigationLink {
                                                RunDetailView(run: run, accent: accent, unit: unit)
                                        .environmentObject(health)
                                            } label: {
                                                RunRow(run: run, accent: accent, unit: unit)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                .font(.subheadline.weight(.semibold))
                                .padding(14)
                                .opaqueCard()
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Running")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await health.requestAndLoad() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(health.isLoading)
                }
            }
            .sheet(isPresented: $showFilters) {
                RunningFilterSheet(filters: $filters, unit: unit)
            }
        }
    }

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last 7 days")
                .font(.headline)
            HStack {
                metric("Avg pace", avgPace.map { Formatters.pace($0, unit: unit) } ?? "—")
                metric("Best pace", bestPace.map { Formatters.pace($0, unit: unit) } ?? "—")
                metric("Runs", "\(last7.count)")
            }
            StressMeter(title: "Run stress", score: weeklyRunStress, accent: accent)
            StressLegendView(compact: true)

            if last7.count >= 2 {
                Chart(last7.sorted { $0.start < $1.start }) { run in
                    LineMark(
                        x: .value("Date", run.start),
                        y: .value("Stress", run.stress)
                    )
                    .foregroundStyle(accent)
                    PointMark(
                        x: .value("Date", run.start),
                        y: .value("Stress", run.stress)
                    )
                    .foregroundStyle(accent)
                }
                .frame(height: 140)
                .chartYScale(domain: 0...100)
            }
        }
        .padding(16)
        .opaqueCard()
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RunningFilterSheet: View {
    @Binding var filters: RunningFilters
    let unit: DistanceUnit
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Distance (\(unit.title))") {
                    Toggle("Minimum", isOn: $filters.useMinDistance)
                    if filters.useMinDistance {
                        Stepper(value: $filters.minDistance, in: 0.5...80, step: 0.5) {
                            Text(String(format: "%.1f %@", filters.minDistance, unit.title))
                        }
                    }
                    Toggle("Maximum", isOn: $filters.useMaxDistance)
                    if filters.useMaxDistance {
                        Stepper(value: $filters.maxDistance, in: 1...100, step: 0.5) {
                            Text(String(format: "%.1f %@", filters.maxDistance, unit.title))
                        }
                    }
                }
                Section("Duration (min)") {
                    Toggle("Minimum", isOn: $filters.useMinDuration)
                    if filters.useMinDuration {
                        Stepper(value: $filters.minDurationMinutes, in: 5...240, step: 5) {
                            Text("\(Int(filters.minDurationMinutes)) min")
                        }
                    }
                    Toggle("Maximum", isOn: $filters.useMaxDuration)
                    if filters.useMaxDuration {
                        Stepper(value: $filters.maxDurationMinutes, in: 10...360, step: 5) {
                            Text("\(Int(filters.maxDurationMinutes)) min")
                        }
                    }
                }
                Section("Pace (min / \(unit.title))") {
                    Toggle("Faster than", isOn: $filters.useMaxPace)
                    if filters.useMaxPace {
                        Stepper(value: $filters.maxPace, in: 3...15, step: 0.25) {
                            Text(Formatters.pace(filters.maxPace, unit: unit))
                        }
                    }
                    Toggle("Slower than", isOn: $filters.useMinPace)
                    if filters.useMinPace {
                        Stepper(value: $filters.minPace, in: 3...20, step: 0.25) {
                            Text(Formatters.pace(filters.minPace, unit: unit))
                        }
                    }
                }
                Section("Date") {
                    Toggle("From", isOn: $filters.useStartDate)
                    if filters.useStartDate {
                        DatePicker("From", selection: $filters.startDate, displayedComponents: .date)
                    }
                    Toggle("To", isOn: $filters.useEndDate)
                    if filters.useEndDate {
                        DatePicker("To", selection: $filters.endDate, displayedComponents: .date)
                    }
                }
                Section {
                    Button("Clear filters") {
                        filters = RunningFilters()
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct RunRow: View {
    let run: RunningWorkout
    let accent: Color
    let unit: DistanceUnit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatters.shortDate.string(from: run.start))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(Formatters.distance(run.distanceMeters, unit: unit))  ·  \(Formatters.duration(run.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let pace = unit.paceMinutesPerUnit(duration: run.duration, meters: run.distanceMeters) {
                    Text(Formatters.pace(pace, unit: unit))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                Text("Stress \(Int(run.stress.rounded()))")
                    .font(.caption)
                    .foregroundStyle(RIRPalette.color(for: run.stress > 75 ? 0 : (run.stress > 55 ? 2 : 4), accent: accent))
            }
        }
        .padding(14)
        .opaqueCard()
    }
}

struct RunDetailView: View {
    let run: RunningWorkout
    let accent: Color
    let unit: DistanceUnit

    @EnvironmentObject private var health: HealthKitService
    @State private var details: RunDetailData?
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    row("Date", Formatters.shortDate.string(from: run.start))
                    row("Distance", Formatters.distance(run.distanceMeters, unit: unit))
                    row("Time", Formatters.duration(run.duration))
                    row("Pace", unit.paceMinutesPerUnit(duration: run.duration, meters: run.distanceMeters).map { Formatters.pace($0, unit: unit) } ?? "—")
                    row("Avg HR", run.averageHeartRate.map { String(format: "%.0f bpm", $0) } ?? "Not recorded")
                }
                .padding(16)
                .opaqueCard()

                routeCard
                heartRateCard
                paceCard

                StressMeter(title: "Run stress", score: run.stress, accent: accent)
                    .padding(16)
                    .opaqueCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text(run.averageHeartRate == nil
                         ? "Stress used pace versus an easy 8:00/km baseline because no heart rate was stored for this run."
                         : "Stress used a TRIMP-style heart-rate calculation (duration × heart-rate reserve).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    StressLegendView(compact: true)
                }
                .padding(16)
                .opaqueCard()
            }
            .padding(16)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Run")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loading = true
            details = await health.loadDetails(for: run)
            loading = false
        }
    }

    @ViewBuilder
    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route")
                .font(.headline)
            if loading && details == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let coords = details?.route, coords.count >= 2 {
                RunRouteMap(locations: coords, accent: accent)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Text("No route recorded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .opaqueCard()
    }

    @ViewBuilder
    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Heart rate")
                .font(.headline)
            if let series = details?.heartRate, series.count >= 2 {
                Chart(series) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("bpm", point.bpm)
                    )
                    .foregroundStyle(accent)
                }
                .frame(height: 160)
            } else if !loading {
                Text("No heart-rate samples for this run.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .opaqueCard()
    }

    @ViewBuilder
    private var paceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pace")
                .font(.headline)
            if let series = details?.pace, series.count >= 2 {
                let points: [PaceSample] = series.map { point in
                    let display = unit == .km ? point.minutesPerKm : point.minutesPerKm * 1.609344
                    return PaceSample(date: point.date, minutesPerKm: display)
                }
                Chart(points) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Pace", point.minutesPerKm)
                    )
                    .foregroundStyle(accent)
                }
                .frame(height: 160)
                .chartYScale(domain: .automatic(includesZero: false))
            } else if !loading {
                Text("No pace series for this run.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .opaqueCard()
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}

struct RunRouteMap: View {
    let locations: [CLLocation]
    let accent: Color
    @State private var position: MapCameraPosition

    init(locations: [CLLocation], accent: Color) {
        self.locations = locations
        self.accent = accent
        if let region = Self.region(for: locations) {
            _position = State(initialValue: .region(region))
        } else {
            _position = State(initialValue: .automatic)
        }
    }

    private var coordinates: [CLLocationCoordinate2D] {
        locations.map(\.coordinate)
    }

    var body: some View {
        Map(position: $position) {
            MapPolyline(coordinates: coordinates)
                .stroke(accent, lineWidth: 3)
            if let start = coordinates.first {
                Marker("Start", coordinate: start)
            }
            if let end = coordinates.last {
                Marker("End", coordinate: end)
            }
        }
        .mapStyle(.standard)
    }

    private static func region(for locations: [CLLocation]) -> MKCoordinateRegion? {
        guard !locations.isEmpty else { return nil }
        let coords = locations.map(\.coordinate)
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
