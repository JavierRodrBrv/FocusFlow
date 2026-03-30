import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents
import os.log

@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowLiveActivity()
    }
}

struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN / NOTIFICATION ---
            FocusFlowWidgetView(context: context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12).opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.status == "break" ? "DESCANSO" : "ENFOQUE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(context.state.status == "break" ? .green : .purple)
                    } icon: {
                        Image(systemName: context.state.status == "break" ? "cup.and.saucer.fill" : "brain.head.profile")
                            .foregroundColor(context.state.status == "break" ? .green : .purple)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(formatTime(seconds: context.state.remainingSeconds))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.yellow)
                            .padding(.trailing, 8)
                    } else {
                        Text(context.state.timerEndDate, style: .timer)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(context.state.status == "break" ? .green : .purple)
                            .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        HStack(spacing: 35) {
                            if #available(iOS 17.0, *) {
                                // --- IOS 17+ INTENTS ---
                                if context.state.isPaused {
                                    Button(intent: ResumeIntent()) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(context.state.status == "break" ? .green : .purple)
                                    }.buttonStyle(.plain)
                                } else {
                                    Button(intent: PauseIntent()) {
                                        Image(systemName: "pause.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.9))
                                    }.buttonStyle(.plain)
                                }
                                Button(intent: StopIntent()) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.red.opacity(0.7))
                                }.buttonStyle(.plain)
                            } else {
                                // --- IOS 16 LINKS ---
                                if context.state.isPaused {
                                    Link(destination: URL(string: "focusflow://resume")!) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(context.state.status == "break" ? .green : .purple)
                                    }
                                } else {
                                    Link(destination: URL(string: "focusflow://pause")!) {
                                        Image(systemName: "pause.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                Link(destination: URL(string: "focusflow://stop")!) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                        }
                    }
                    .padding(.top, 15)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "break" ? "cup.and.saucer.fill" : "brain.head.profile")
                    .foregroundColor(context.state.isPaused ? .yellow : (context.state.status == "break" ? .green : .purple))
            } compactTrailing: {
                if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.timerEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(context.state.status == "break" ? .green : .purple)
                        .frame(width: 40)
                }
            } minimal: {
                Image(systemName: context.state.status == "break" ? "cup.and.saucer.fill" : "brain.head.profile")
                    .foregroundColor(context.state.isPaused ? .yellow : (context.state.status == "break" ? .green : .purple))
            }
            .widgetURL(URL(string: "focusflow://sync"))
            .keylineTint(Color.purple)
        }
    }
}
