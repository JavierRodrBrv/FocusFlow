import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// 1. EL MODELO DE DATOS (Incluido aquí para evitar errores de Scope)
public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var targetEndDate: Date
        public var isPaused: Bool
        public var totalDuration: Double
        public var progress: Double
        public var status: String
        public var remainingSeconds: Int
        
        public init(targetEndDate: Date, isPaused: Bool, totalDuration: Double, progress: Double, status: String, remainingSeconds: Int) {
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

// 2. ACCIONES EN SEGUNDO PLANO (App Intents)
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

// 3. DISEÑO PREMIUM
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // LOCK SCREEN
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 3).frame(width: 38, height: 38)
                    Circle().trim(from: 0, to: context.state.progress)
                        .stroke(context.state.status == "focus" ? Color.purple : Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 38, height: 38).rotationEffect(.degrees(-90))
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(context.state.status.capitalized)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if context.state.isPaused {
                    Text(formatTime(context.state.remainingSeconds))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .frame(width: 85, alignment: .trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .foregroundColor(.purple)
                        .padding(.leading, 10)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(formatTime(context.state.remainingSeconds))
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
                            .frame(width: 70)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Botón circular único que alterna estado
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
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .foregroundColor(.purple)
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill").foregroundColor(.yellow).font(.caption2)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.purple)
                        .frame(width: 35)
                }
            } minimal: {
                Image(systemName: "timer").foregroundColor(.purple)
            }
            .widgetURL(URL(string: "focusflow://open"))
            .keylineTint(Color.purple)
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
