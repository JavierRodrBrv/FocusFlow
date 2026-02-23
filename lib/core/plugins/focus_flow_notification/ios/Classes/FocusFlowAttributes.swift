import ActivityKit
import Foundation

public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var targetEndDate: Date
        public var isPaused: Bool
        public var totalDuration: Double
        public var progress: Double
        public var status: String
        public var remainingSeconds: Int // <--- NUEVO: Para mostrar tiempo estático al pausar
        
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
    
    public init(name: String) {
        self.name = name
    }
}
