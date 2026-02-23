import ActivityKit
import WidgetKit
import SwiftUI

struct FocusFlowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusFlowAttributes.self) { context in
            // --- LOCK SCREEN (La tarjeta negra) ---
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 45, height: 45)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(context.state.status == "focus" ? Color.purple : Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 45, height: 45)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.status == "focus" ? "Focus" : "Break")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                } else {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .frame(width: 85)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.12))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // --- EXPANDED ---
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .padding(.leading, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.targetEndDate, style: .timer)
                        .font(.title2)
                        .monospacedDigit()
                        .foregroundColor(.purple)
                        .padding(.trailing, 10)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 25) {
                        Link(destination: URL(string: "focusflow://pause")!) {
                            Image(systemName: "pause.fill").font(.title3).padding(12).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        Link(destination: URL(string: "focusflow://resume")!) {
                            Image(systemName: "play.fill").font(.title3).padding(12).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        Link(destination: URL(string: "focusflow://stop")!) {
                            Image(systemName: "xmark").font(.title3).padding(12).background(Color.red.opacity(0.2)).clipShape(Circle())
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                }
            } compactLeading: {
                // --- COMPACTO IZQUIERDA (Más estrecho) ---
                Image(systemName: context.state.status == "focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .imageScale(.small)
                    .foregroundColor(.purple)
            } compactTrailing: {
                // --- COMPACTO DERECHA (Más estrecho) ---
                Text(context.state.targetEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.purple)
                    .frame(width: 38)
            } minimal: {
                Image(systemName: "timer").foregroundColor(.purple)
            }
        }
    }
}
