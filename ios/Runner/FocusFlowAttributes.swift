import ActivityKit
import Foundation

public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Estado dinámico que se actualiza frecuentemente
        public var targetEndDate: Date
        public var startDate: Date // Added
        public var isPaused: Bool
        public var totalDuration: Double
        public var progress: Double
        public var status: String // "focus", "break", "finished"
        public var remainingSeconds: Int // Added
        
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

    // Propiedades fijas que no cambian
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
}
