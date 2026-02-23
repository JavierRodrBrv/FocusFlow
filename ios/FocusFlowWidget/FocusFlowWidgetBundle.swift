import WidgetKit
import SwiftUI
import ActivityKit

// 1. MODELO DE DATOS
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

// 2. DISEÑO DE LA LIVE ACTIVITY (AJUSTADO PARA EVITAR SALTO DE LÍNEA)
struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- PANTALLA DE BLOQUEO ---
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 3)
                        .frame(width: 38, height: 38)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(context.state.status == "focus" ? Color.purple : Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 38, height: 38)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(context.state.status == "focus" ? "Focus" : "Break")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                } else {
                    // Ajuste de ancho y escala para evitar saltos de línea
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.8) // Permite que el texto se encoja un poco si no cabe
                        .lineLimit(1) // Prohíbe el salto de línea
                        .foregroundColor(.white)
                        .frame(width: 95, alignment: .trailing) // Un poco más de ancho para asegurar
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // --- EXPANDED ---
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                        .padding(.leading, 12)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.title3)
                        .monospacedDigit()
                        .minimumScaleFactor(0.9)
                        .lineLimit(1)
                        .foregroundColor(.purple)
                        .padding(.trailing, 12)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 30) {
                        Link(destination: URL(string: "focusflow://pause")!) {
                            Image(systemName: "pause.fill").font(.title3).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        Link(destination: URL(string: "focusflow://resume")!) {
                            Image(systemName: "play.fill").font(.title3).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        Link(destination: URL(string: "focusflow://stop")!) {
                            Image(systemName: "xmark").font(.title3).padding(10).background(Color.red.opacity(0.2)).clipShape(Circle())
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
                }
                
            } compactLeading: {
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .imageScale(.small)
                    .foregroundColor(.purple)
            } compactTrailing: {
                Text(context.state.targetEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.purple)
                    .frame(width: 38)
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
