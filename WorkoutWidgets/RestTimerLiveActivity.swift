import ActivityKit
import SwiftUI
import WidgetKit

private func setProgressText(_ state: RestTimerAttributes.ContentState) -> String? {
    guard state.targetSets > 0 else { return nil }
    return "Set \(min(state.setsCompleted + 1, state.targetSets)) of \(state.targetSets)"
}

struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3.weight(.semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.exerciseName)
                        .font(.headline)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(context.attributes.sessionLabel)
                        if let progress = setProgressText(context.state) {
                            Text("·")
                            Text(progress)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Text(timerInterval: Date()...context.state.restEndDate, countsDown: true)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .multilineTextAlignment(.trailing)
            }
            .padding(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.restEndDate, countsDown: true)
                        .font(.title3.monospacedDigit().weight(.bold))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.sessionLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Text(context.state.exerciseName)
                            .lineLimit(1)
                        if let progress = setProgressText(context.state) {
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(progress)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.restEndDate, countsDown: true)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .frame(width: 36)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
