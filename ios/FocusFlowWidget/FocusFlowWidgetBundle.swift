import WidgetKit
import SwiftUI
import ActivityKit

// 1. MODELO DE DATOS (IMPORTANTE: Debe ser idéntico al del plugin)
public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var targetEndDate: Date
        public var isPaused: Bool
        public var pausedTime: Date?
        public var totalDuration: Double
        public var progress: Double
        public var status: String
    }
    public var name: String
}

// 2. DISEÑO DE LA LIVE ACTIVITY (MÁS ESTRECHO Y PREMIUM)
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- PANTALLA DE BLOQUEO (LOCK SCREEN) ---
            HStack(spacing: 12) {
                // Anillo de progreso con icono central
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 3.5)
                        .frame(width: 42, height: 42)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(context.state.status == "focus" ? Color.purple : Color.green, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(context.state.status == "focus" ? "Focus" : "Break")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .frame(width: 82)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12)) // Azul profundo premium
            
        } dynamicIsland: { context in
            DynamicIsland {
                // --- VISTA EXPANDIDA ---
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                        .padding(.leading, 12)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.title2)
                        .monospacedDigit()
                        .foregroundColor(.purple)
                        .padding(.trailing, 12)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 28) {
                        Link(destination: URL(string: "focusflow://pause")!) {
                            Image(systemName: "pause.fill")
                                .font(.title3)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        Link(destination: URL(string: "focusflow://resume")!) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        Link(destination: URL(string: "focusflow://stop")!) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .padding(12)
                                .background(Color.red.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                }
                
            } compactLeading: {
                // --- COMPACTO IZQUIERDA (Estrecho) ---
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .imageScale(.small)
                    .foregroundColor(.purple)
                    .padding(.leading, 2)
            } compactTrailing: {
                // --- COMPACTO DERECHA (Estrecho) ---
                Text(context.state.targetEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.purple)
                    .frame(width: 36)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.purple)
            }
            .widgetURL(URL(string: "focusflow://open"))
            .keylineTint(Color.purple)
        }
    }
}

// 3. PUNTO DE ENTRADA
@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowLiveActivity()
    }
}
