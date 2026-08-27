import SwiftUI
import Charts

struct RunningView: View {
    @StateObject private var health = HealthKitService()
    @AppStorage("accentName") private var accentName = AccentOption.orange.rawValue

    private var accent: Color {
        AccentOption(rawValue: accentName)?.color ?? .orange
    }

    private var recent: [RunningWorkout] {
        health.runs
    }

    private var last7: [RunningWorkout] {
        let cutoff = Date().addingTimeInterval(-7 * 86_400)
        return recent.filter { $0.start >= cutoff }
    }

    private var avgPace: Double? {
        let paces = last7.compactMap(\.paceMinPerKm)
        guard !paces.isEmpty else { return nil }
        return paces.reduce(0, +) / Double(paces.count)
    }

    private var bestPace: Double? {
        last7.compactMap(\.paceMinPerKm).min()
    }

    private var weeklyRunStress: Double {
        StressCalculator.averageRunStress(recent)
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
                        Text("Recent runs")
                            .font(.headline)
                        if health.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if recent.isEmpty {
                            Text("No running workouts found in Apple Health. Record a run in the Fitness or Health app, then pull to refresh.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(16)
                                .opaqueCard()
                        } else {
                            ForEach(recent) { run in
                                NavigationLink {
                                    RunDetailView(run: run, accent: accent)
                                } label: {
                                    RunRow(run: run, accent: accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Running")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await health.requestAndLoad() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(health.isLoading)
                }
            }
            .task {
                await health.requestAndLoad()
            }
        }
    }

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last 7 days")
                .font(.headline)
            HStack {
                metric("Avg pace", avgPace.map(Formatters.pace) ?? "—")
                metric("Best pace", bestPace.map(Formatters.pace) ?? "—")
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

struct RunRow: View {
    let run: RunningWorkout
    let accent: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatters.shortDate.string(from: run.start))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(String(format: "%.2f km", run.distanceKilometers))  ·  \(Formatters.duration(run.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let pace = run.paceMinPerKm {
                    Text(Formatters.pace(pace))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                Text("Stress \(Int(run.stress.rounded()))")
                    .font(.caption)
                    .foregroundStyle(RIRPalette.color(for: run.stress > 75 ? 0 : (run.stress > 55 ? 2 : 3), accent: accent))
            }
        }
        .padding(14)
        .opaqueCard()
    }
}

struct RunDetailView: View {
    let run: RunningWorkout
    let accent: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    row("Date", Formatters.shortDate.string(from: run.start))
                    row("Distance", String(format: "%.2f km", run.distanceKilometers))
                    row("Time", Formatters.duration(run.duration))
                    row("Pace", run.paceMinPerKm.map(Formatters.pace) ?? "—")
                    row("Avg HR", run.averageHeartRate.map { String(format: "%.0f bpm", $0) } ?? "Not recorded")
                }
                .padding(16)
                .opaqueCard()

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
