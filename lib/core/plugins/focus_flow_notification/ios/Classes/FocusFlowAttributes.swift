import ActivityKit
import Foundation

public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Estado dinámico que se actualiza frecuentemente
        public var targetEndDate: Date
        public var isPaused: Bool
        public var pausedTime: Date? // Para mostrar el tiempo estático si se pausa
        public var totalDuration: Double
        public var progress: Double
        public var status: String // "focus", "break", "finished"
        
        public init(targetEndDate: Date, isPaused: Bool, pausedTime: Date? = nil, totalDuration: Double, progress: Double, status: String) {
            self.targetEndDate = targetEndDate
            self.isPaused = isPaused
            self.pausedTime = pausedTime
            self.totalDuration = totalDuration
            self.progress = progress
            self.status = status
        }
    }

    // Propiedades fijas que no cambian
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
}
