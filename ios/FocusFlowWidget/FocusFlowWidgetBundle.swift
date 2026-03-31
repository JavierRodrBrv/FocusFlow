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
                        Text(context.state.statusLabel)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(context.state.themeColor)
                    } icon: {
                        Image(systemName: context.state.iconName)
                            .foregroundColor(context.state.themeColor)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.status == "overtime" {
                        Text(context.state.timerEndDate, style: .timer)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.red)
                            .padding(.trailing, 8)
                    } else if context.state.isPaused {
                        Text(formatTime(seconds: context.state.remainingSeconds))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.yellow)
                            .padding(.trailing, 8)
                    } else {
                        Text(context.state.timerEndDate, style: .timer)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(context.state.themeColor)
                            .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        if let instruction = context.state.instructionText {
                            Text(instruction)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(context.state.themeColor)
                                .transition(.opacity)
                        }
                        
                        HStack(spacing: 35) {
                            if #available(iOS 17.0, *) {
                                // --- IOS 17+ INTENTS ---
                                if context.state.showStartFocusButton {
                                    Button(intent: StartFocusIntent()) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(context.state.themeColor)
                                    }.buttonStyle(.plain)
                                } else if context.state.isPaused {
                                    Button(intent: ResumeIntent()) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.purple)
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
                                if context.state.showStartFocusButton {
                                    Link(destination: URL(string: "focusflow://startfocus")!) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(context.state.themeColor)
                                    }
                                } else if context.state.isPaused {
                                    Link(destination: URL(string: "focusflow://resume")!) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.purple)
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
                Image(systemName: context.state.iconName)
                    .foregroundColor(context.state.themeColor)
            } compactTrailing: {
                if context.state.status == "focus_ready" {
                    Text("00:00")
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                } else if context.state.status == "overtime" {
                    Text(context.state.timerEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                } else if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.timerEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(context.state.themeColor)
                        .frame(width: 40)
                }
            } minimal: {
                Image(systemName: context.state.iconName)
                    .foregroundColor(context.state.themeColor)
            }
            .widgetURL(URL(string: "focusflow://sync"))
            .keylineTint(Color.purple)
        }
    }
}
