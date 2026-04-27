import SwiftUI

enum TimerPhase: Equatable {
    case work
    case rest
    case stopwatch

    var displayName: String {
        switch self {
        case .work: return "Focus"
        case .rest: return "Break"
        case .stopwatch: return "Stopwatch"
        }
    }

    var accentColor: Color {
        switch self {
        case .work: return Color(red: 0.93, green: 0.27, blue: 0.27)
        case .rest: return Color(red: 0.30, green: 0.69, blue: 0.45)
        case .stopwatch: return Color(red: 0.20, green: 0.50, blue: 0.85)
        }
    }
}
