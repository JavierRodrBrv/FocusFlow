import ActivityKit
import Foundation

struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state updated frequently
        var targetEndDate: Date
        var isPaused: Bool
        var pausedTime: Date? // Used to show static time when paused
        var totalDuration: Double
        var progress: Double
        var status: String // "focus", "break", "finished"
    }

    // Fixed non-changing properties about the activity
    var name: String
}
