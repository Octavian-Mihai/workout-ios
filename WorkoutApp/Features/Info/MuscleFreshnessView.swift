import SwiftUI
import SwiftData

struct MuscleFreshnessEntry: Identifiable {
    let muscle: MuscleGroup
    let freshness: Double

    var id: String { muscle.id }
}

struct MuscleFreshnessView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(AppTheme.self) private var theme

    private var groupedMuscles: [(region: String, entries: [MuscleFreshnessEntry])] {
        let freshness = StressCalculator.allMuscleFreshness(sessions: sessions)
        let regions = ["Upper body", "Arms", "Lower body", "Trunk"]
        return regions.compactMap { region in
            let entries = MuscleGroup.allCases
                .filter { $0.region == region }
                .map { MuscleFreshnessEntry(muscle: $0, freshness: freshness[$0.rawValue] ?? 100) }
                .sorted { $0.freshness < $1.freshness }
            return entries.isEmpty ? nil : (region, entries)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Per-muscle recovery based on recent training load. Higher scores mean the muscle is more ready to train.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(groupedMuscles, id: \.region) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.region)
                            .font(.headline)

                        ForEach(group.entries) { entry in
                            MuscleFreshnessRow(entry: entry)
                        }
                    }
                    .padding(16)
                    .opaqueCard()
                }
            }
            .padding(16)
        }
        .background(theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Muscle freshness")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MuscleFreshnessRow: View {
    let entry: MuscleFreshnessEntry
    @Environment(AppTheme.self) private var theme

    private var color: Color {
        let rgb = StressCalculator.freshnessColor(for: entry.freshness)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.muscle.rawValue)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(entry.freshness.rounded()))%")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.mutedFill)
                    Capsule()
                        .fill(color)
                        .frame(width: max(6, geo.size.width * min(max(entry.freshness / 100, 0), 1)))
                }
            }
            .frame(height: 6)
            Text(StressCalculator.freshnessLabel(for: entry.freshness))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct MuscleFreshnessCompactCard: View {
    let sessions: [WorkoutSession]
    @Environment(AppTheme.self) private var theme

    private var mostFatigued: [MuscleFreshnessEntry] {
        let freshness = StressCalculator.allMuscleFreshness(sessions: sessions)
        return MuscleGroup.allCases
            .map { MuscleFreshnessEntry(muscle: $0, freshness: freshness[$0.rawValue] ?? 100) }
            .sorted { $0.freshness < $1.freshness }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        NavigationLink {
            MuscleFreshnessView()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Muscle freshness")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ForEach(mostFatigued) { entry in
                    HStack(spacing: 8) {
                        Text(entry.muscle.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(Int(entry.freshness.rounded()))%")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(freshnessColor(for: entry.freshness))
                    }
                }
            }
            .padding(12)
            .opaqueCard()
        }
        .buttonStyle(.plain)
    }

    private func freshnessColor(for score: Double) -> Color {
        let rgb = StressCalculator.freshnessColor(for: score)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
