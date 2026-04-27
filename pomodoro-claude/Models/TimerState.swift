import SwiftUI

enum TimerState: Equatable {
    case idle
    case running(TimerPhase)
    case paused(TimerPhase)

    var isActive: Bool {
        if case .idle = self { return false }
        return true
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }

    var currentPhase: TimerPhase? {
        switch self {
        case .idle: return nil
        case .running(let p), .paused(let p): return p
        }
    }

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .running(let p): return p.displayName
        case .paused(let p): return "\(p.displayName) — Paused"
        }
    }

    var accentColor: Color {
        switch self {
        case .idle: return .gray
        case .running(let p): return p.accentColor
        case .paused(let p): return p.accentColor.opacity(0.5)
        }
    }
}
