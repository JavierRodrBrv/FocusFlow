import ActivityKit
import WidgetKit
import SwiftUI

struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN / NOTIFICATION BANNER ---
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(context.state.status == "focus" ? "Focus Session" : "Break Time", 
                          systemImage: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if context.state.isPaused {
                        Text("Session Paused")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    } else {
                        Text("Keep going!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                    } else {
                        Text(context.state.targetEndDate, style: .timer)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(width: 90)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.2))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // --- EXPANDED VIEW (Mantener pulsada la isla) ---
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                        .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.status.capitalized)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(context.state.targetEndDate, style: .timer)
                            .font(.title2)
                            .monospacedDigit()
                            .foregroundColor(.purple)
                    }
                    .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Botones de acción (Deep Links)
                    HStack(spacing: 20) {
                        Link(destination: URL(string: "focusflow://pause")!) {
                            Label("Pause", systemImage: "pause.fill")
                                .padding(10)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(20)
                        }
                        Link(destination: URL(string: "focusflow://resume")!) {
                            Label("Resume", systemImage: "play.fill")
                                .padding(10)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(20)
                        }
                        Link(destination: URL(string: "focusflow://stop")!) {
                            Label("Stop", systemImage: "xmark")
                                .padding(10)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(20)
                        }
                    }
                    .padding(.top, 10)
                }
                
            } compactLeading: {
                // --- COMPACT LEFT (El icono en la isla cerrada) ---
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .foregroundColor(.purple)
            } compactTrailing: {
                // --- COMPACT RIGHT (El tiempo en la isla cerrada) ---
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .monospacedDigit()
                        .foregroundColor(.purple)
                        .font(.system(size: 14, weight: .semibold))
                }
            } minimal: {
                // --- MINIMAL (Cuando hay otra actividad en la isla) ---
                Image(systemName: "timer")
                    .foregroundColor(.purple)
            }
            .widgetURL(URL(string: "focusflow://open"))
        }
    }
}
