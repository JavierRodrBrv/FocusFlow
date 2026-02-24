import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// 1. MODELO
public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var targetEndDate: Date
        public var isPaused: Bool
        public var totalDuration: Double
        public var progress: Double
        public var status: String
        public var remainingSeconds: Int
    }
    public var name: String
    public init(name: String) { self.name = name }
}

// 2. INTENT OPTIMIZADO (EVITA BLOQUEOS)
struct TimerToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    @Parameter(title: "Action") var action: String
    init() {}
    init(action: String) { self.action = action }
    
    func perform() async throws -> some IntentResult {
        let identifier = action == "pause" ? "com.andaluzcode.focusflow.pause" : "com.andaluzcode.focusflow.play"
        Task {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(identifier as CFString), nil, nil, true)
        }
        return .result()
    }
}

// 3. DISEÑO COMPACTO Y PREMIUM CON CONTROLES EN LOCK SCREEN
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN / NOTIFICATION CENTER ---
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 2.5).frame(width: 32, height: 32)
                        Circle().trim(from: 0, to: context.state.progress)
                            .stroke(context.state.status == "focus" ? Color.purple : Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 32, height: 32).rotationEffect(.degrees(-90))
                        Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").font(.system(size: 12)).foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: -2) {
                        Text(context.state.status.capitalized).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        Text(context.state.isPaused ? "Paused" : "Running").font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    if context.state.isPaused {
                        Text(formatTime(context.state.remainingSeconds)).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.yellow)
                    } else {
                        Text(context.state.targetEndDate, style: .timer).font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit().foregroundColor(.white).frame(width: 75, alignment: .trailing)
                    }
                }
                
                // --- BOTÓN DE CONTROL EN LA TARJETA (LOCK SCREEN) ---
                HStack {
                    Spacer()
                    Button(intent: TimerToggleIntent(action: context.state.isPaused ? "play" : "pause")) {
                        HStack(spacing: 8) {
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            Text(context.state.isPaused ? "Resume" : "Pause")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(context.state.isPaused ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(15)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDIDA
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").foregroundColor(.purple).font(.title3).padding(.leading, 8).padding(.top, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        if context.state.isPaused {
                            Text(formatTime(context.state.remainingSeconds)).font(.title3).monospacedDigit().foregroundColor(.yellow)
                        } else {
                            Text(context.state.targetEndDate, style: .timer).font(.title3).monospacedDigit().foregroundColor(.purple).frame(width: 60)
                        }
                    }.padding(.trailing, 8).padding(.top, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: TimerToggleIntent(action: context.state.isPaused ? "play" : "pause")) {
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 18)).padding(10).background(context.state.isPaused ? Color.green.opacity(0.2) : Color.white.opacity(0.1)).clipShape(Circle())
                    }.buttonStyle(.plain).padding(.bottom, 6)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").imageScale(.small).foregroundColor(.purple)
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill").foregroundColor(.yellow).font(.system(size: 10))
                } else {
                    Text(context.state.targetEndDate, style: .timer).monospacedDigit().font(.system(size: 11, weight: .bold)).foregroundColor(.purple).frame(width: 32)
                }
            } minimal: {
                Image(systemName: "timer").foregroundColor(.purple)
            }
            .widgetURL(URL(string: "focusflow://open"))
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
