import ActivityKit
import Foundation

public struct FocusFlowAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isPaused: Bool
        public var status: String
        public var remainingSeconds: Int
        
        // --- NUEVO: Propiedades para Timer Nativo ---
        // --- NATIVE LOOP PARAMS ---
        public var cycleStartDate: Date
        public var focusDurationSeconds: Int
        public var breakDurationSeconds: Int
        public var pauseDate: Date?
        public var showSkip: Bool
        
        public init(isPaused: Bool, status: String, remainingSeconds: Int, cycleStartDate: Date, focusDurationSeconds: Int, breakDurationSeconds: Int, pauseDate: Date?, showSkip: Bool) {
            self.isPaused = isPaused
            self.status = status
            self.remainingSeconds = remainingSeconds
            self.cycleStartDate = cycleStartDate
            self.focusDurationSeconds = focusDurationSeconds
            self.breakDurationSeconds = breakDurationSeconds
            self.pauseDate = pauseDate
            self.showSkip = showSkip
        }
    }
    public var name: String
    public init(name: String) { self.name = name }
}

extension FocusFlowAttributes.ContentState {
    var activePhaseInfo: (isBreak: Bool, startDate: Date, endDate: Date) {
        if isPaused {
            return (status == "break", Date(), Date().addingTimeInterval(TimeInterval(remainingSeconds)))
        }
        if breakDurationSeconds == 0 || status == "waiting" {
            let start = cycleStartDate
            let end = cycleStartDate.addingTimeInterval(TimeInterval(focusDurationSeconds))
            return (status == "break", start, end)
        }
        let totalCycleSeconds = focusDurationSeconds + breakDurationSeconds
        let elapsed = Int(Date().timeIntervalSince(cycleStartDate))
        if elapsed < 0 {
            return (false, cycleStartDate, cycleStartDate.addingTimeInterval(TimeInterval(focusDurationSeconds)))
        }
        let elapsedCycles = elapsed / totalCycleSeconds
        let currentCycleStart = cycleStartDate.addingTimeInterval(TimeInterval(elapsedCycles * totalCycleSeconds))
        let currentCycleCompletedDuration = elapsed % totalCycleSeconds
        
        if currentCycleCompletedDuration < focusDurationSeconds {
            return (false, currentCycleStart, currentCycleStart.addingTimeInterval(TimeInterval(focusDurationSeconds)))
        } else {
            return (true, currentCycleStart.addingTimeInterval(TimeInterval(focusDurationSeconds)), currentCycleStart.addingTimeInterval(TimeInterval(totalCycleSeconds)))
        }
    }
}
