import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// Helper function para mostrar el tiempo formateado (MM:SS) cuando está pausado
func formatTime(seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

// --- ATTRIBUTES ---
public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startDate: Date
        public var targetEndDate: Date
        public var isPaused: Bool
        public var totalDuration: Double
        public var progress: Double
        public var status: String
        public var remainingSeconds: Int
        
        public init(startDate: Date, targetEndDate: Date, isPaused: Bool, totalDuration: Double, progress: Double, status: String, remainingSeconds: Int) {
            self.startDate = startDate
            self.targetEndDate = targetEndDate
            self.isPaused = isPaused
            self.totalDuration = totalDuration
            self.progress = progress
            self.status = status
            self.remainingSeconds = remainingSeconds
        }
    }
    public var name: String
    public init(name: String) { self.name = name }
}

// --- WIDGET DEFINITION ---
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN / NOTIFICATION CENTER ---
            HStack(spacing: 12) {
                // 1. Ring & Icon
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
                
                // 2. Status Text
                
                    Text(context.state.status == "focus" ? "Focus" : "Descanso")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                
                // 3. Timer Display
                if context.state.isPaused {
                    Text("PAUSADO")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.trailing, 4)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .padding(.trailing, 4)
                }
                
                // 4. Play/Pause Action Button
                if #available(iOS 17.0, *) {
                    if context.state.isPaused {
                        Button(intent: ResumeIntent()) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(Color.purple.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: PauseIntent()) {
                            Image(systemName: "pause.fill")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Link(destination: URL(string: context.state.isPaused ? "focusflow://resume" : "focusflow://pause")!) {
                         Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(context.state.isPaused ? Color.purple.opacity(0.2) : Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
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
                    // SOLUCION BUG VISUAL EXPANDED: Condición para mostrar el tiempo estático si está pausado
                    if context.state.isPaused {
                        Text(formatTime(seconds: context.state.remainingSeconds))
                            .font(.title2)
                            .monospacedDigit()
                            .foregroundColor(.yellow)
                            .padding(.trailing, 10)
                    } else {
                        Text(context.state.targetEndDate, style: .timer)
                            .font(.title2)
                            .monospacedDigit()
                            .foregroundColor(.purple)
                            .padding(.trailing, 10)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if #available(iOS 17.0, *) {
                            if context.state.isPaused {
                                Button(intent: ResumeIntent()) {
                                    Image(systemName: "play.fill")
                                        .font(.largeTitle)
                                        .frame(width: 60, height: 60)
                                        .background(Color.purple.opacity(0.2))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(intent: PauseIntent()) {
                                    Image(systemName: "pause.fill")
                                        .font(.largeTitle)
                                        .frame(width: 60, height: 60)
                                        .background(Color.white.opacity(0.15))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Link(destination: URL(string: context.state.isPaused ? "focusflow://resume" : "focusflow://pause")!) {
                                Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                    .font(.largeTitle)
                                    .frame(width: 60, height: 60)
                                    .background(context.state.isPaused ? Color.purple.opacity(0.2) : Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.top, 10)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .imageScale(.small)
                    .foregroundColor(context.state.isPaused ? .yellow : .purple)
            } compactTrailing: {
                // SOLUCION BUG VISUAL COMPACT: Condición para la isla cerrada
                if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.yellow)
                        .minimumScaleFactor(0.8)
                        .frame(minWidth: 40, maxWidth: 60)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.purple)
                        .minimumScaleFactor(0.8)
                        .frame(minWidth: 40, maxWidth: 60)
                }
            } minimal: {
                Image(systemName: "timer").foregroundColor(context.state.isPaused ? .yellow : .purple)
            }
        }
    }
}

// --- INTENTS ---

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pausar Timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.pause" as CFString), nil, nil, true)
        
        for activity in Activity<FocusFlowAttributes>.activities {
            var state = activity.content.state
            if !state.isPaused {
                let remaining = state.targetEndDate.timeIntervalSinceNow
                state.remainingSeconds = max(0, Int(remaining))
                state.isPaused = true
                
                if #available(iOS 16.2, *) {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                } else {
                    await activity.update(using: state)
                }
            }
        }
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct ResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reanudar Timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.play" as CFString), nil, nil, true)
        
        for activity in Activity<FocusFlowAttributes>.activities {
            var state = activity.content.state
            if state.isPaused {
                // Calcular nueva fecha objetivo
                let newTarget = Date().addingTimeInterval(TimeInterval(state.remainingSeconds))
                // ¡CLAVE! Calcular nuevo inicio para que el progreso (circulo) se dibuje bien
                let newStart = newTarget.addingTimeInterval(-state.totalDuration)
                
                state.targetEndDate = newTarget
                state.startDate = newStart
                state.isPaused = false
                
                if #available(iOS 16.2, *) {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                } else {
                    await activity.update(using: state)
                }
            }
        }
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
        
        for activity in Activity<FocusFlowAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        return .result()
    }
}

@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowLiveActivity()
    }
}
