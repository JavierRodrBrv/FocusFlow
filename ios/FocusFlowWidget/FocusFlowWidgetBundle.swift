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
        
        // --- NATIVE LOOP PARAMS ---
        public var cycleStartDate: Date
        public var focusDurationSeconds: Int
        public var breakDurationSeconds: Int
        public var pauseDate: Date?
        
        public init(isPaused: Bool, status: String, remainingSeconds: Int, cycleStartDate: Date, focusDurationSeconds: Int, breakDurationSeconds: Int, pauseDate: Date?) {
            self.isPaused = isPaused
            self.status = status
            self.remainingSeconds = remainingSeconds
            self.cycleStartDate = cycleStartDate
            self.focusDurationSeconds = focusDurationSeconds
            self.breakDurationSeconds = breakDurationSeconds
            self.pauseDate = pauseDate
        }
    }
    public var name: String
    public init(name: String) { self.name = name }
}

extension FocusFlowAttributes.ContentState {
    var activePhaseInfo: (isBreak: Bool, startDate: Date, endDate: Date) {
        if isPaused {
            return (status == "break", Date(), Date().addingTimeInterval(TimeInterval(remainingSeconds)))
        }
        if breakDurationSeconds == 0 || status == "waiting" {
            let start = cycleStartDate
            let end = cycleStartDate.addingTimeInterval(TimeInterval(focusDurationSeconds))
            return (status == "break", start, end)
        }
        let totalCycleSeconds = focusDurationSeconds + breakDurationSeconds
        let elapsed = Int(Date().timeIntervalSince(cycleStartDate))
        if elapsed < 0 {
            return (false, cycleStartDate, cycleStartDate.addingTimeInterval(TimeInterval(focusDurationSeconds)))
        }
        let elapsedCycles = elapsed / totalCycleSeconds
        let currentCycleStart = cycleStartDate.addingTimeInterval(TimeInterval(elapsedCycles * totalCycleSeconds))
        let currentCycleCompletedDuration = elapsed % totalCycleSeconds
        
        if currentCycleCompletedDuration < focusDurationSeconds {
            return (false, currentCycleStart, currentCycleStart.addingTimeInterval(TimeInterval(focusDurationSeconds)))
        } else {
            return (true, currentCycleStart.addingTimeInterval(TimeInterval(focusDurationSeconds)), currentCycleStart.addingTimeInterval(TimeInterval(totalCycleSeconds)))
        }
    }
}

// --- WIDGET DEFINITION ---
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            let phaseInfo = context.state.activePhaseInfo
            let isBreak = phaseInfo.isBreak
            let displayStatus = context.state.status == "waiting" ? "Listo" : (isBreak ? "Descanso" : "Focus")

            // --- LOCK SCREEN ---
            HStack(spacing: 12) {
                Image(systemName: isBreak ? "cup.and.saucer.fill" : "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(isBreak ? .green : .purple)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayStatus)
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
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.yellow)
                        .padding(.trailing, 2)
                } else {
                    Text(timerInterval: phaseInfo.startDate...phaseInfo.endDate)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .padding(.trailing, 2)
                }
                
                // Botón de Acción
                if #available(iOS 17.0, *) {
                    HStack(spacing: 6) {
                        if context.state.isPaused {
                            Button(intent: ResumeIntent()) {
                                Image(systemName: "play.fill")
                                    .font(.body)
                                    .frame(width: 34, height: 34)
                                    .background(Color.purple.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: PauseIntent()) {
                                Image(systemName: "pause.fill")
                                    .font(.body)
                                    .frame(width: 34, height: 34)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button(intent: NextPhaseIntent()) {
                            Image(systemName: "forward.end.fill")
                                .font(.body)
                                .frame(width: 34, height: 34)
                                .background(Color.blue.opacity(0.2))
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
                let phaseInfo = context.state.activePhaseInfo
                let isBreak = phaseInfo.isBreak
                // --- EXPANDED ---
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: isBreak ? "cup.and.saucer.fill" : "brain.head.profile")
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
                        Text(timerInterval: phaseInfo.startDate...phaseInfo.endDate)
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

                            Button(intent: NextPhaseIntent()) {
                                Image(systemName: "forward.end.fill")
                                    .font(.title)
                                    .frame(width: 50, height: 50)
                                    .background(Color.blue.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

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
                let isBreak = context.state.activePhaseInfo.isBreak
                Image(systemName: isBreak ? "cup.and.saucer.fill" : "brain.head.profile")
                    .foregroundColor(context.state.isPaused ? .yellow : .purple)
            } compactTrailing: {
                let phaseInfo = context.state.activePhaseInfo
                if context.state.isPaused {
                    Text(formatTime(seconds: context.state.remainingSeconds))
                        .monospacedDigit()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.yellow)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: 40, alignment: .trailing)
                } else {
                    Text(timerInterval: phaseInfo.startDate...phaseInfo.endDate)
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
struct NextPhaseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Siguiente Fase"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        os_log("[FocusFlowWidget] NextPhaseIntent.perform()", log: .default, type: .info)
        
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.next" as CFString), nil, nil, true)
        
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pausar Timer"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        os_log("[FocusFlowWidget] PauseIntent.perform()", log: .default, type: .info)
        let now = Date()
        let activities = Activity<FocusFlowAttributes>.activities
        os_log("[FocusFlowWidget] Found %d activities for PauseIntent", log: .default, type: .info, activities.count)
        
        // ESTRATEGIA DE VISIBILIDAD: Usamos update para no desaparecer del Dynamic Island
        // El budget se reseteará cuando el usuario abra la App (Rebirth en Foreground)
        var previousState: FocusFlowAttributes.ContentState? = nil
        var lastRemainingSeconds = 0
        if let activity = activities.first {
            if #available(iOS 16.2, *) {
                previousState = activity.content.state
            } else {
                previousState = activity.contentState
            }
            if let state = previousState {
                if !state.isPaused {
                    let phaseInfo = state.activePhaseInfo
                    let remaining = phaseInfo.endDate.timeIntervalSince(now)
                    lastRemainingSeconds = max(0, Int(remaining))
                } else {
                    lastRemainingSeconds = state.remainingSeconds
                }
            }
        }

        // 1. Persistir
        if let defaults = UserDefaults(suiteName: appGroupName) {
            defaults.set(true, forKey: "isPaused")
            defaults.set(lastRemainingSeconds, forKey: "remainingSeconds")
            defaults.set(now.timeIntervalSince1970, forKey: "lastWidgetActionTime")
            defaults.synchronize()
        }
        
        // 2. Notificar a Dart
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.pause" as CFString), nil, nil, true)

        // 3. Update Activity (Mantener visibilidad)
        var currentStatus = "focus"
        if let activity = activities.first, let stateOld = previousState {
            currentStatus = stateOld.status

            let state = FocusFlowAttributes.ContentState(
                isPaused: true,
                status: currentStatus,
                remainingSeconds: lastRemainingSeconds,
                cycleStartDate: stateOld.cycleStartDate,
                focusDurationSeconds: stateOld.focusDurationSeconds,
                breakDurationSeconds: stateOld.breakDurationSeconds,
                pauseDate: now
            )
            
            if #available(iOS 16.2, *) {
                try? await activity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                await activity.update(using: state)
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
        let now = Date()
        let activities = Activity<FocusFlowAttributes>.activities
        os_log("[FocusFlowWidget] Found %d activities for ResumeIntent", log: .default, type: .info, activities.count)
        
        // ESTRATEGIA DE VISIBILIDAD: Usamos update para no desaparecer
        var currentStatus = "focus"
        if let activity = activities.first {
            if #available(iOS 16.2, *) {
                currentStatus = activity.content.state.status
            } else {
                currentStatus = activity.contentState.status
            }
        }

        // 1. Persistir
        var lastRemaining = 0
        if let defaults = UserDefaults(suiteName: appGroupName) {
            lastRemaining = defaults.integer(forKey: "remainingSeconds")
            defaults.set(false, forKey: "isPaused")
            defaults.set(now.timeIntervalSince1970, forKey: "lastWidgetActionTime")
            defaults.synchronize()
        }
        
        // 2. Notificar
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName("com.andaluzcode.focusflow.play" as CFString), nil, nil, true)

        // 3. Update active activity
        if let activity = activities.first {
            let stateOld: FocusFlowAttributes.ContentState
            if #available(iOS 16.2, *) {
                stateOld = activity.content.state
            } else {
                stateOld = activity.contentState
            }
            
            // Calculamos cuánto tiempo ha estado pausado para retrasar el inicio del ciclo
            let pausedDuration = now.timeIntervalSince(stateOld.pauseDate ?? now)
            let newCycleStart = stateOld.cycleStartDate.addingTimeInterval(pausedDuration)
            
            currentStatus = stateOld.status

            let state = FocusFlowAttributes.ContentState(
                isPaused: false,
                status: currentStatus,
                remainingSeconds: lastRemaining,
                cycleStartDate: newCycleStart,
                focusDurationSeconds: stateOld.focusDurationSeconds,
                breakDurationSeconds: stateOld.breakDurationSeconds,
                pauseDate: nil
            )
            
            if #available(iOS 16.2, *) {
                try? await activity.update(ActivityContent(state: state, staleDate: state.activePhaseInfo.endDate.addingTimeInterval(60)))
            } else {
                await activity.update(using: state)
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
