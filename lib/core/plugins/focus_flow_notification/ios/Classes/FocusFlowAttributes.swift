import ActivityKit
import Foundation

public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isPaused: Bool
        public var status: String
        public var remainingSeconds: Int
        
        // --- NUEVO: Propiedades para Timer Nativo ---
        // Al proveer The timestamp de inicio y fin, Text(timerInterval) de SwiftUI
        // hace la cuenta regresiva nativamente sin consumir "updates" por segundo.
        public var timerStartDate: Date
        public var timerEndDate: Date
        // Cuando pausamos, guardamos el timestamp de la pausa. Text() se quedará congelado ahí.
        public var pauseDate: Date?
        
        public init(isPaused: Bool, status: String, remainingSeconds: Int, timerStartDate: Date, timerEndDate: Date, pauseDate: Date?) {
            self.isPaused = isPaused
            self.status = status
            self.remainingSeconds = remainingSeconds
            self.timerStartDate = timerStartDate
            self.timerEndDate = timerEndDate
            self.pauseDate = pauseDate
        }
    }
    public var name: String
    public init(name: String) { self.name = name }
}
