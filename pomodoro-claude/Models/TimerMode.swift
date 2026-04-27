import Foundation

enum TimerMode: String, CaseIterable, Equatable {
    case pomodoro
    case stopwatch

    var displayName: String {
        switch self {
        case .pomodoro: return "Pomodoro"
        case .stopwatch: return "Stopwatch"
        }
    }
}
