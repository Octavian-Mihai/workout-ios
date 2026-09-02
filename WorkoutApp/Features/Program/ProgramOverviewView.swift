import SwiftUI

struct ProgramOverviewView: View {
    let program: Program
    var onDone: () -> Void

    @Environment(AppTheme.self) private var theme

    private var snapshot: ProgramOverviewSnapshot {
        ProgramOverviewSnapshot.build(from: program)
    }

    private var accent: Color { theme.accent }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    totals
                    caption
                    insights
                    muscleBreakdown
                }
                .padding(16)
            }
            .background(theme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Program overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snapshot.programName)
                .font(.title2.weight(.bold))
            Text(daySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var daySubtitle: String {
        let days = snapshot.dayCount
        let dayWord = days == 1 ? "day" : "days"
        return "\(days) \(dayWord) in the rotation"
    }

    private var totals: some View {
        HStack(spacing: 0) {
            statBlock(value: "\(snapshot.dayCount)", label: "Days")
            divider
            statBlock(value: "\(snapshot.exerciseCount)", label: "Exercises")
            divider
            statBlock(value: "\(snapshot.plannedSets)", label: "Sets")
        }
        .padding(14)
        .opaqueCard()
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.cardBorder)
            .frame(width: 1, height: 36)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var caption: some View {
        Text("Primary muscles get full exercise and set credit. Secondary muscles get half, matching Anatomy 101 volume. Totals count each lift once; per-muscle numbers can add up to more because compounds credit more than one muscle.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var insights: some View {
        if !snapshot.insights.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Insight")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(snapshot.insights.enumerated()), id: \.offset) { _, note in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "text.bubble")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(accent)
                                .padding(.top, 2)
                            Text(note)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .opaqueCard()
            }
        }
    }

    @ViewBuilder
    private var muscleBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By muscle")
                .font(.headline)
            if snapshot.rows.isEmpty {
                Text("Add exercises to see how the split loads each muscle.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .opaqueCard()
            } else {
                let maxBar = snapshot.rows.map { $0.sortValue(usingSets: snapshot.usesSetVolume) }.max() ?? 1
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(snapshot.regionGroups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(group.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(regionSummary(group))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(group.rows) { row in
                                muscleRow(row, maxBar: max(maxBar, 0.01))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .opaqueCard()
            }
        }
    }

    private func regionSummary(_ group: ProgramRegionGroup) -> String {
        let exercises = Formatters.trimmedNumber(group.exerciseCredit, decimals: 1)
        if snapshot.usesSetVolume {
            let sets = Formatters.trimmedNumber(group.setCredit, decimals: 1)
            return "\(exercises) ex · \(sets) sets"
        }
        return "\(exercises) ex"
    }

    private func muscleRow(_ row: ProgramMuscleRow, maxBar: Double) -> some View {
        let barValue = row.sortValue(usingSets: snapshot.usesSetVolume)
        let fraction = min(max(barValue / maxBar, 0), 1)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Text(muscleDetail(row))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                Capsule()
                    .fill(theme.mutedFill)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(accent)
                            .frame(width: geo.size.width * max(fraction, fraction > 0 ? 0.04 : 0))
                    }
            }
            .frame(height: 8)
        }
    }

    private func muscleDetail(_ row: ProgramMuscleRow) -> String {
        let exercises = Formatters.trimmedNumber(row.exerciseCredit, decimals: 1)
        if snapshot.usesSetVolume {
            let sets = Formatters.trimmedNumber(row.setCredit, decimals: 1)
            return "\(exercises) ex · \(sets) sets"
        }
        return "\(exercises) ex"
    }
}
