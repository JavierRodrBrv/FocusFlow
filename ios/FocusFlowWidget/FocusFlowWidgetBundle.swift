import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// 1. MODELO
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

// 2. INTENT
struct TimerToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    @Parameter(title: "Action") var action: String
    init() {}
    init(action: String) { self.action = action }
    func perform() async throws -> some IntentResult {
        let identifier = action == "pause" ? "com.andaluzcode.focusflow.pause" : "com.andaluzcode.focusflow.play"
        Task { CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(identifier as CFString), nil, nil, true) }
        return .result()
    }
}

// 3. DISEÑO
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // LOCK SCREEN
            HStack(spacing: 15) {
                ZStack {
                    if context.state.isPaused {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 3).frame(width: 36, height: 36)
                    } else {
                        ProgressView(timerInterval: context.state.startDate...context.state.targetEndDate, countsDown: true, label: { EmptyView() }, currentValueLabel: { EmptyView() })
                            .progressViewStyle(.circular)
                            .tint(context.state.status == "focus" ? Color.purple : Color.green)
                            .scaleEffect(1.1)
                    }
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").font(.system(size: 12)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: -2) {
                    Text(context.state.status.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .kerning(1)
                        .foregroundColor(context.state.status == "focus" ? Color.purple : Color.green)
                    
                    if context.state.isPaused {
                        Text(formatTime(context.state.remainingSeconds)).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.yellow)
                    } else {
                        Text(context.state.targetEndDate, style: .timer).font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit().foregroundColor(.white).frame(width: 70, alignment: .leading)
                    }
                }
                Spacer()
                Button(intent: TimerToggleIntent(action: context.state.isPaused ? "play" : "pause")) {
                    Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill").font(.system(size: 18)).foregroundColor(context.state.isPaused ? Color.green : Color.white).frame(width: 44, height: 44).background(Color.white.opacity(0.1)).clipShape(Circle())
                }.buttonStyle(.plain)
            }.padding(.horizontal, 20).padding(.vertical, 10).activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").foregroundColor(Color.purple).padding(.leading, 10).padding(.top, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(formatTime(context.state.remainingSeconds)).font(.title3).bold().monospacedDigit().foregroundColor(.yellow).padding(.trailing, 10).padding(.top, 10)
                    } else {
                        Text(context.state.targetEndDate, style: .timer).font(.title3).bold().monospacedDigit().foregroundColor(Color.purple).frame(width: 60).padding(.trailing, 10).padding(.top, 10)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: TimerToggleIntent(action: context.state.isPaused ? "play" : "pause")) {
                        Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill").font(.title3).padding(10).background(context.state.isPaused ? Color.green.opacity(0.2) : Color.white.opacity(0.1)).clipShape(Circle())
                    }.buttonStyle(.plain).padding(.bottom, 8)
                }
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill").imageScale(.small).foregroundColor(Color.purple).padding(.leading, 4)
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill").foregroundColor(.yellow).font(.system(size: 10))
                } else {
                    Text(context.state.targetEndDate, style: .timer).monospacedDigit().font(.system(size: 14, weight: .bold)).foregroundColor(Color.purple).frame(width: 42, alignment: .center).padding(.trailing, 2)
                }
            } minimal: {
                Image(systemName: "timer").foregroundColor(Color.purple)
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
