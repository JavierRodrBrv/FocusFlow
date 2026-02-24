import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN (La tarjeta negra) ---
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(context.state.status == "focus" ? Color.purple : Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                
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
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.pause" as CFString), nil, nil, true)
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct ResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reanudar Timer"
    static var openAppWhenRun: Bool = true // Force open to ensure resume works from suspension
    
    init() {}
    
    func perform() async throws -> some IntentResult {
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
