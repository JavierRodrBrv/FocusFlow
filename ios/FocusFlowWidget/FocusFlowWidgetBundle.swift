import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// --- 1. ACCIONES EN SEGUNDO PLANO (APP INTENTS) ---
struct TimerToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    
    @Parameter(title: "Action")
    var action: String

    init() {}
    init(action: String) { self.action = action }

    func perform() async throws -> some IntentResult {
        let identifier = action == "pause" ? "com.andaluzcode.focusflow.pause" : "com.andaluzcode.focusflow.play"
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(identifier as CFString), nil, nil, true)
        return .result()
    }
}

// --- 2. DISEÑO DEL WIDGET ---
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // LOCK SCREEN
            HStack {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 3).frame(width: 38, height: 38)
                    Circle().trim(from: 0, to: context.state.progress)
                        .stroke(context.state.status == "focus" ? Color.purple : Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 38, height: 38).rotationEffect(.degrees(-90))
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").font(.system(size: 14)).foregroundColor(.white)
                }
                VStack(alignment: .leading) {
                    Text(context.state.status.capitalized).font(.headline).foregroundColor(.white)
                    Text(context.state.isPaused ? "Paused" : "Running").font(.caption).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                if context.state.isPaused {
                    Text(formatTime(context.state.remainingSeconds)).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer).font(.system(size: 28, weight: .bold, design: .rounded)).monospacedDigit().foregroundColor(.white).frame(width: 85)
                }
            }.padding().activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").foregroundColor(.purple).padding(.leading, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(formatTime(context.state.remainingSeconds)).font(.title2).monospacedDigit().foregroundColor(.yellow).padding(.trailing, 10)
                    } else {
                        Text(context.state.targetEndDate, style: .timer).font(.title2).monospacedDigit().foregroundColor(.purple).padding(.trailing, 10).frame(width: 70)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // --- BOTÓN ÚNICO QUE NO ABRE LA APP ---
                    Button(intent: TimerToggleIntent(action: context.state.isPaused ? "play" : "pause")) {
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .padding(12)
                            .background(context.state.isPaused ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").foregroundColor(.purple)
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill").foregroundColor(.yellow).font(.caption2)
                } else {
                    Text(context.state.targetEndDate, style: .timer).monospacedDigit().font(.system(size: 12, weight: .bold)).foregroundColor(.purple).frame(width: 35)
                }
            } minimal: {
                Image(systemName: "timer").foregroundColor(.purple)
            }
        }
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowLiveActivity()
    }
}
