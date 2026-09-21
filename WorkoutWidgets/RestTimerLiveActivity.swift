import ActivityKit
import SwiftUI
import WidgetKit

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
                    Text(context.attributes.sessionLabel)
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
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.exerciseName)
                        .font(.subheadline)
                        .lineLimit(1)
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
