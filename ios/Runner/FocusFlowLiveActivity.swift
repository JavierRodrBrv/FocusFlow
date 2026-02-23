import ActivityKit
import WidgetKit
import SwiftUI

struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // Lock Screen/Banner UI
            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    // Left: Status Icon & Text
                    HStack(spacing: 8) {
                        Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text(context.state.status.capitalized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            if context.state.isPaused {
                                Text("Paused")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            } else {
                                Text("Running")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Right: Timer
                    if context.state.isPaused {
                        // Show remaining time as static text if possible, or just "PAUSED"
                        // Since we can't easily calculate static remaining time from Date in pure SwiftUI without a state update,
                        // we rely on the passed 'pausedTime' or just show --:--
                        Text(context.state.pausedTime ?? Date(), style: .time) 
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow.opacity(0.9))
                    } else {
                        Text(context.state.targetEndDate, style: .timer)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Progress Bar
                ProgressView(value: context.state.progress, total: 1.0)
                    .tint(context.state.status == "focus" ? .purple : .green)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.06, green: 0.09, blue: 0.16)) // Dark Blue background
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                            .foregroundColor(.purple)
                        Text(context.state.status.capitalized)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    // Trailing content
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Big Timer & Controls
                    VStack {
                        if context.state.isPaused {
                            Text("PAUSED")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.yellow)
                        } else {
                            Text(context.state.targetEndDate, style: .timer)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        
                        // Controls (Deep Links)
                        HStack(spacing: 30) {
                            Link(destination: URL(string: "focusflow://pause")!) {
                                Label("Pause", systemImage: "pause.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            Link(destination: URL(string: "focusflow://resume")!) {
                                Label("Resume", systemImage: "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            Link(destination: URL(string: "focusflow://stop")!) {
                                Label("Stop", systemImage: "stop.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .foregroundColor(context.state.status == "focus" ? .purple : .green)
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.circle")
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .monospacedDigit()
                        .frame(maxWidth: 40)
                        .foregroundColor(.purple)
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.purple)
            }
            .widgetURL(URL(string: "focusflow://open"))
            .keylineTint(Color.purple)
        }
    }
}
