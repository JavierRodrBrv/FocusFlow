import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN (Versión Ultraligera) ---
            HStack(spacing: 15) {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 22))
                    .foregroundColor(context.state.status == "focus" ? .purple : .green)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.status == "focus" ? "Focus" : "Break")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .frame(width: 85)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // --- EXPANDED ---
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .padding(.leading, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.title2)
                        .monospacedDigit()
                        .foregroundColor(.purple)
                        .padding(.trailing, 10)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Controles Grandes
                    HStack(spacing: 40) {
                        if #available(iOS 17.0, *) {
                            Button(intent: PauseIntent()) {
                                Image(systemName: "pause.fill")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Button(intent: ResumeIntent()) {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Button(intent: StopIntent()) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(Color.red.opacity(0.25))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Fallback para iOS 16 (Usando Link pero más grande)
                            Link(destination: URL(string: "focusflow://pause")!) {
                                Image(systemName: "pause.fill").font(.title2).frame(width: 50, height: 50).background(Color.white.opacity(0.15)).clipShape(Circle())
                            }
                            Link(destination: URL(string: "focusflow://resume")!) {
                                Image(systemName: "play.fill").font(.title2).frame(width: 50, height: 50).background(Color.white.opacity(0.15)).clipShape(Circle())
                            }
                            Link(destination: URL(string: "focusflow://stop")!) {
                                Image(systemName: "xmark").font(.title2).frame(width: 50, height: 50).background(Color.red.opacity(0.25)).clipShape(Circle())
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                    .padding(.top, 10)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .imageScale(.small)
                    .foregroundColor(.purple)
            } compactTrailing: {
                Text(context.state.targetEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.purple)
                    .frame(width: 38)
            } minimal: {
                Image(systemName: "timer").foregroundColor(.purple)
            }
        }
    }
}

// --- INTENTS FOR INTERACTIVE WIDGETS (iOS 17+) ---

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pausar Timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        if #available(iOS 16.1, *) {
            for activity in Activity<FocusFlowAttributes>.activities {
                var newState = activity.contentState
                newState.isPaused = true
                
                let remaining = Int(newState.targetEndDate.timeIntervalSince(Date()))
                newState.remainingSeconds = remaining > 0 ? remaining : 0
                
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: newState, staleDate: nil)
                    await activity.update(content)
                } else {
                    await activity.update(using: newState)
                }
            }
        }
        
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.pause" as CFString), nil, nil, true)
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct ResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reanudar Timer"
    static var openAppWhenRun: Bool = false
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        if #available(iOS 16.1, *) {
            for activity in Activity<FocusFlowAttributes>.activities {
                var newState = activity.contentState
                newState.isPaused = false
                
                newState.targetEndDate = Date().addingTimeInterval(TimeInterval(newState.remainingSeconds))
                
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: newState, staleDate: nil)
                    await activity.update(content)
                } else {
                    await activity.update(using: newState)
                }
            }
        }
        
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.play" as CFString), nil, nil, true)
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct StopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Detener Timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.stop" as CFString), nil, nil, true)
        return .result()
    }
}
