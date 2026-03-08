import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents
import os.log

// Helper function para mostrar el tiempo formateado (MM:SS) cuando está pausado
func formatTime(seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

// --- ATTRIBUTES ---
public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isPaused: Bool
        public var status: String
        public var remainingSeconds: Int
        
        public var timerStartDate: Date
        public var timerEndDate: Date
        public var pauseDate: Date?
        
        public init(isPaused: Bool, status: String, remainingSeconds: Int, timerStartDate: Date, timerEndDate: Date, pauseDate: Date?) {
            self.isPaused = isPaused
            self.status = status
            self.remainingSeconds = remainingSeconds
            self.timerStartDate = timerStartDate
            self.timerEndDate = timerEndDate
            self.pauseDate = pauseDate
        }
    }
    public var name: String
    public init(name: String) { self.name = name }
}

// --- WIDGET DEFINITION ---
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN ---
            HStack(spacing: 12) {
                Image(systemName: context.state.status == "break" ? "cup.and.saucer.fill" : "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(context.state.status == "break" ? .green : .purple)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.status == "waiting" ? "Listo" : (context.state.status == "focus" ? "Focus" : "Descanso"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(context.state.status == "waiting" ? "Voltea el móvil" : (context.state.isPaused ? "Pausado" : "En curso"))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Timer Display — simple y fiable
                if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.yellow)
                        .padding(.trailing, 8)
                } else {
                    Text(context.state.timerEndDate, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
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
                    Image(systemName: context.state.status == "break" ? "cup.and.saucer.fill" : "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .padding(.leading, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // PAUSA: tiempo congelado estático. CORRIENDO: countdown nativo iOS.
                    if context.state.isPaused {
                        Text(formatTime(seconds: context.state.remainingSeconds))
                            .font(.title2)
                            .monospacedDigit()
                            .foregroundColor(.yellow)
                            .padding(.trailing, 10)
                    } else {
                        Text(context.state.timerEndDate, style: .timer)
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
                Image(systemName: context.state.status == "break" ? "cup.and.saucer.fill" : "brain.head.profile")
                    .foregroundColor(context.state.isPaused ? .yellow : .purple)
            } compactTrailing: {
                if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.yellow)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: 40, alignment: .trailing)
                } else {
                    Text(context.state.timerEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.purple)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: 40, alignment: .trailing)
                }
            } minimal: {
                Image(systemName: "timer").foregroundColor(context.state.isPaused ? .yellow : .purple)
            }
        }
    }
}

// --- INTENTS AUTÓNOMOS (APP GROUPS) ---

let appGroupName = "group.com.andaluzcode.focusFlow"

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pausar Timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        os_log("[FocusFlowWidget] PauseIntent.perform()", log: .default, type: .info)
        // Notificamos a Dart (solo lo oirá si está vivo)
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.pause" as CFString), nil, nil, true)
        
        let activities = Activity<FocusFlowAttributes>.activities
        os_log("[FocusFlowWidget] Found %d activities for PauseIntent", log: .default, type: .info, activities.count)
        
        for activity in activities {
            var state = activity.content.state
            if !state.isPaused {
                let now = Date()
                let remaining = state.timerEndDate.timeIntervalSince(now)
                state.remainingSeconds = max(0, Int(remaining))
                state.isPaused = true
                state.pauseDate = now
                state.status = "focus" // Default fallback
                
                // Guardamos en AppGroup antes de actualizar, para que Dart pueda leer esta reconciliación luego
                if let defaults = UserDefaults(suiteName: appGroupName) {
                    defaults.set(state.isPaused, forKey: "isPaused")
                    defaults.set(state.remainingSeconds, forKey: "remainingSeconds")
                    defaults.set(now.timeIntervalSince1970, forKey: "lastWidgetActionTime")
                }
                
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
        os_log("[FocusFlowWidget] ResumeIntent.perform()", log: .default, type: .info)
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.play" as CFString), nil, nil, true)
        
        let activities = Activity<FocusFlowAttributes>.activities
        os_log("[FocusFlowWidget] Found %d activities for ResumeIntent", log: .default, type: .info, activities.count)
        
        for activity in activities {
            var state = activity.content.state
            if state.isPaused {
                let now = Date()
                let newEndDate = now.addingTimeInterval(TimeInterval(state.remainingSeconds))
                
                state.timerEndDate = newEndDate
                state.pauseDate = nil
                state.isPaused = false
                
                // Guardamos en App Group
                if let defaults = UserDefaults(suiteName: appGroupName) {
                    defaults.set(state.isPaused, forKey: "isPaused")
                    defaults.set(state.remainingSeconds, forKey: "remainingSeconds")
                    defaults.set(now.timeIntervalSince1970, forKey: "lastWidgetActionTime")
                }
                
                if #available(iOS 16.2, *) {
                    await activity.update(ActivityContent(state: state, staleDate: newEndDate.addingTimeInterval(60)))
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
        
        // Guardar estado detenido en el group
        if let defaults = UserDefaults(suiteName: appGroupName) {
            defaults.set(true, forKey: "isStopped")
            defaults.set(Date().timeIntervalSince1970, forKey: "lastWidgetActionTime")
        }
        
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
