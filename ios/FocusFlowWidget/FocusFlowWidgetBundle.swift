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
            // --- LOCK SCREEN (Versión Ultra-Estable) ---
            HStack(spacing: 12) {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 20))
                    .foregroundColor(context.state.status == "focus" ? .purple : .green)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.status == "focus" ? "Focus" : "Descanso")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(context.state.isPaused ? "Pausado" : "En curso")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .frame(width: 90)
                }
                
                // Botón de Acción
                if #available(iOS 17.0, *) {
                    if context.state.isPaused {
                        Button(intent: ResumeIntent()) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(Color.purple.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: PauseIntent()) {
                            Image(systemName: "pause.fill")
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                    HStack(spacing: 30) {
                        if #available(iOS 17.0, *) {
                            if context.state.isPaused {
                                Button(intent: ResumeIntent()) {
                                    Image(systemName: "play.fill")
                                        .font(.title)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.15))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(intent: PauseIntent()) {
                                    Image(systemName: "pause.fill")
                                        .font(.title)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.15))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }

                            Button(intent: StopIntent()) {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .frame(width: 50, height: 50)
                                    .background(Color.red.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .foregroundColor(context.state.isPaused ? .yellow : .purple)
            } compactTrailing: {
                if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.purple)
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
