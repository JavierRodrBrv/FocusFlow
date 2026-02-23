import WidgetKit
import SwiftUI
import ActivityKit

// 2. DISEÑO DE LA LIVE ACTIVITY
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // Diseño Bloqueo
            HStack {
                VStack(alignment: .leading) {
                    Text(context.state.status == "focus" ? "Focus" : "Break")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.title)
                        .bold()
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.title)
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.largeTitle)
                        .monospacedDigit()
                        .foregroundColor(.purple)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.purple)
            } compactTrailing: {
                Text(context.state.targetEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.caption2)
                    .foregroundColor(.purple)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.purple)
            }
        }
    }
}

// 3. PUNTO DE ENTRADA
@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowLiveActivity()
    }
}
