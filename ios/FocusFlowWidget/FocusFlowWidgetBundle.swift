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

// 2. INTENT OPTIMIZADO
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

// 3. DISEÑO ULTRA-PREMIUM CORREGIDO
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN / NOTIFICATION CENTER ---
            HStack(spacing: 15) {
                // Anillo de progreso CORREGIDO
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(
                            context.state.status == "focus" ? Color.purple : Color.green,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(context.state.status == "focus" ? "FOCUS" : "BREAK")
                        .font(.system(size: 14, weight: .black))
                        .letterSpacing(1)
                        .foregroundColor(context.state.status == "focus" ? .purple : .green)
                    
                    if context.state.isPaused {
                        Text(formatTime(context.state.remainingSeconds))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                    } else {
                        Text(context.state.targetEndDate, style: .timer)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .frame(width: 90, alignment: .leading)
                    }
                }
                
                Spacer()
                
                // BOTÓN SOLO ICONO
                Button(intent: TimerToggleIntent(action: context.state.isPaused ? "play" : "pause")) {
                    ZStack {
                        Circle()
                            .fill(context.state.isPaused ? Color.green.opacity(0.15) : Color.white.opacity(0.1))
                            .frame(width: 50, height: 50)
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 22))
                            .foregroundColor(context.state.isPaused ? .green : .white)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDIDA
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .padding(.leading, 12).padding(.top, 12)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        if context.state.isPaused {
                            Text(formatTime(context.state.remainingSeconds))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.yellow)
                        } else {
                            Text(context.state.targetEndDate, style: .timer)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.purple)
                                .frame(width: 70)
                        }
                    }
                    .padding(.trailing, 12).padding(.top, 12)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: TimerToggleIntent(action: context.state.isPaused ? "play" : "pause")) {
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .padding(14)
                            .background(context.state.isPaused ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .imageScale(.medium)
                    .foregroundColor(.purple)
                    .padding(.leading, 4)
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.trailing, 4)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .monospacedDigit()
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.purple)
                        .frame(width: 45, alignment: .center)
                        .padding(.trailing, 4)
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
