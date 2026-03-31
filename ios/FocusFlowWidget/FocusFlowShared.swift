import WidgetKit
import SwiftUI
import ActivityKit
import os.log
import AppIntents

// --- CONFIGURACIÓN GLOBAL ---
public let appGroupName = "group.com.andaluzcode.focusFlow"

// --- ATRIBUTOS (IDENTIDAD ÚNICA) ---
@available(iOS 16.2, *)
public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isPaused: Bool
        public var status: String
        public var remainingSeconds: Int
        public var timerStartDate: Date
        public var timerEndDate: Date
        public var pauseDate: Date?
        
        public init(isPaused: Bool, status: String, remainingSeconds: Int, 
                    timerStartDate: Date, timerEndDate: Date, pauseDate: Date?) {
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


// --- LÓGICA DE UI CENTRALIZADA ---
@available(iOS 16.2, *)
extension FocusFlowAttributes.ContentState {
    var themeColor: Color {
        if status == "break" { return .green }
        if status == "overtime" { return .red }
        if status == "focus_ready" { return .green }
        return .purple
    }
    
    var statusLabel: String {
        if status == "break" { return "DESCANSO" }
        if status == "overtime" { return "TIEMPO EXTRA" }
        if status == "focus_ready" { return "ENFOQUE" }
        return "ENFOQUE"
    }
    
    var iconName: String {
        if status == "break" { return "cup.and.saucer.fill" }
        if status == "overtime" { return "exclamationmark.circle.fill" }
        return "brain.head.profile"
    }
    
    var instructionText: String? {
        if status == "overtime" { return "PLAY PARA SIGUIENTE ENFOQUE" }
        return nil
    }
    
    var showStartFocusButton: Bool {
        return status == "break" || status == "focus_ready" || status == "overtime"
    }
}

// --- INTENTS NATIVOS (iOS 17+) ---

@available(iOS 17.0, *)
public struct PauseIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Pausar"
    public static var isDiscoverable: Bool = true
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        os_log("[FocusFlow] Intent: PAUSE triggered", log: .default, type: .info)
        let now = Date()
        let activities = Activity<FocusFlowAttributes>.activities
        guard let activity = activities.first else { return .result() }
        
        let state = activity.content.state
        let remaining = max(0, Int(state.timerEndDate.timeIntervalSince(now)))
        
        if let defaults = UserDefaults(suiteName: appGroupName) {
            defaults.set(true, forKey: "isPaused")
            defaults.set(remaining, forKey: "remainingSeconds")
            defaults.set(now.timeIntervalSince1970, forKey: "lastWidgetActionTime")
            defaults.synchronize()
        }
        
        let newState = FocusFlowAttributes.ContentState(
            isPaused: true, status: state.status, remainingSeconds: remaining,
            timerStartDate: now, timerEndDate: now.addingTimeInterval(TimeInterval(remaining)),
            pauseDate: now
        )
        
        try await activity.update(ActivityContent(state: newState, staleDate: nil))
        return .result()
    }
}

@available(iOS 17.0, *)
public struct ResumeIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Reanudar"
    public static var isDiscoverable: Bool = true
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        os_log("[FocusFlow] Intent: RESUME triggered", log: .default, type: .info)
        let now = Date()
        let activities = Activity<FocusFlowAttributes>.activities
        guard let activity = activities.first else { return .result() }
        
        let state = activity.content.state
        let remaining = state.remainingSeconds
        let newEndDate = now.addingTimeInterval(TimeInterval(remaining))
        
        if let defaults = UserDefaults(suiteName: appGroupName) {
            defaults.set(false, forKey: "isPaused")
            defaults.set(remaining, forKey: "remainingSeconds")
            defaults.set(now.timeIntervalSince1970, forKey: "lastWidgetActionTime")
            defaults.synchronize()
        }
        
        let newState = FocusFlowAttributes.ContentState(
            isPaused: false, status: state.status, remainingSeconds: remaining,
            timerStartDate: now, timerEndDate: newEndDate, pauseDate: nil
        )
        
        try await activity.update(ActivityContent(state: newState, staleDate: nil))
        return .result()
    }
}

@available(iOS 17.0, *)
public struct StopIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Detener"
    public static var isDiscoverable: Bool = true
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        os_log("[FocusFlow] Intent: STOP triggered", log: .default, type: .info)
        if let defaults = UserDefaults(suiteName: appGroupName) {
            defaults.set(true, forKey: "isStopped")
            defaults.set(Date().timeIntervalSince1970, forKey: "lastWidgetActionTime")
            defaults.synchronize()
        }
        for activity in Activity<FocusFlowAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
public struct StartFocusIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Iniciar Enfoque"
    public static var isDiscoverable: Bool = true
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        os_log("[FocusFlow] Intent: START_FOCUS triggered", log: .default, type: .info)
        let now = Date()
        let activities = Activity<FocusFlowAttributes>.activities
        guard let activity = activities.first else { return .result() }
        
        let state = activity.content.state
        // Default to 25 mins if not set in App Group
        var focusDurationSeconds = 25 * 60
        
        let newEndDate = now.addingTimeInterval(TimeInterval(focusDurationSeconds))
        
        if let defaults = UserDefaults(suiteName: appGroupName) {
            let userDuration = defaults.integer(forKey: "totalDuration")
            if userDuration > 0 {
                focusDurationSeconds = userDuration
            }
            
            defaults.set(false, forKey: "isPaused")
            defaults.set(focusDurationSeconds, forKey: "remainingSeconds")
            defaults.set(now.timeIntervalSince1970 * 1000, forKey: "nativeFocusStartTimestamp")
            defaults.set(newEndDate.timeIntervalSince1970 * 1000, forKey: "targetEndTime")
            defaults.set("focus", forKey: "status")
            defaults.set(now.timeIntervalSince1970, forKey: "lastWidgetActionTime")
            defaults.synchronize()
        }
        
        let newState = FocusFlowAttributes.ContentState(
            isPaused: false, status: "focus", remainingSeconds: focusDurationSeconds,
            timerStartDate: now, timerEndDate: newEndDate, pauseDate: nil
        )
        
        try await activity.update(ActivityContent(state: newState, staleDate: nil))
        return .result()
    }
}

// --- UTILIDADES ---
public func formatTime(seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

// --- VISTAS COMPARTIDAS ---

@available(iOS 16.2, *)
public struct FocusFlowWidgetView: View {
    public let context: ActivityViewContext<FocusFlowAttributes>
    public init(context: ActivityViewContext<FocusFlowAttributes>) {
        self.context = context
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.statusLabel)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(context.state.themeColor)
                Text("FocusFlow")
                    .font(.headline)
            }
            
            Spacer()
            
            if context.state.status == "focus_ready" {
                Text("00:00")
                    .monospacedDigit()
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            } else if context.state.status == "overtime" {
                Text(context.state.timerEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
            } else if context.state.isPaused {
                Text(formatTime(seconds: context.state.remainingSeconds))
                    .monospacedDigit()
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
            } else {
                Text(timerInterval: context.state.timerStartDate...context.state.timerEndDate, countsDown: true)
                    .monospacedDigit()
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // --- CONTROLES HÍBRIDOS ---
            HStack(spacing: 8) {
                if #available(iOS 17.0, *) {
                    if context.state.showStartFocusButton {
                        Button(intent: StartFocusIntent()) {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundColor(context.state.themeColor)
                        }.buttonStyle(.plain)
                    } else if context.state.isPaused {
                        Button(intent: ResumeIntent()) {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundColor(context.state.themeColor)
                        }.buttonStyle(.plain)
                    } else {
                        Button(intent: PauseIntent()) {
                            Image(systemName: "pause.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                        }.buttonStyle(.plain)
                    }
                } else {
                    if context.state.showStartFocusButton {
                        Link(destination: URL(string: "focusflow://startfocus")!) {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundColor(context.state.themeColor)
                        }
                    } else if context.state.isPaused {
                        Link(destination: URL(string: "focusflow://resume")!) {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundColor(context.state.themeColor)
                        }
                    } else {
                        Link(destination: URL(string: "focusflow://pause")!) {
                            Image(systemName: "pause.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .padding(.leading, 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
}
