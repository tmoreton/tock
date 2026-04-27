import SwiftUI
import AppKit
import Combine

@MainActor
final class TimerEngine: ObservableObject {
    static let modeDefaultsKey = "timerMode"

    @Published private(set) var state: TimerState = .idle
    @Published private(set) var displayTime: TimeInterval = 0
    @Published private(set) var totalForCurrentPhase: TimeInterval = 0

    @Published var mode: TimerMode = .pomodoro {
        didSet {
            guard mode != oldValue else { return }
            UserDefaults.standard.set(mode.rawValue, forKey: Self.modeDefaultsKey)
        }
    }

    @AppStorage("workMinutes") var workMinutes: Int = 25
    @AppStorage("breakMinutes") var breakMinutes: Int = 5
    @AppStorage("playSoundOnComplete") var playSoundOnComplete: Bool = true

    // Pomodoro countdown bookkeeping.
    private var phaseEndDate: Date?
    private var pausedRemaining: TimeInterval?

    // Stopwatch count-up bookkeeping.
    private var phaseStartDate: Date?
    private var accumulatedElapsed: TimeInterval = 0

    private var ticker: Timer?

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.modeDefaultsKey),
           let saved = TimerMode(rawValue: raw) {
            self._mode = Published(initialValue: saved)
        }
    }

    /// Arc length to draw on the ring, 0...1.
    /// Pomodoro: drains from 1 → 0 as time runs out.
    /// Stopwatch: stays full while running (visual indicator only).
    var progress: Double {
        switch state.currentPhase {
        case .work, .rest:
            guard totalForCurrentPhase > 0 else { return 0 }
            return min(1, max(0, displayTime / totalForCurrentPhase))
        case .stopwatch:
            return 1
        case nil:
            return 0
        }
    }

    var isActive: Bool { state.isActive }

    func toggle() {
        switch state {
        case .idle: start()
        case .running: pause()
        case .paused: resume()
        }
    }

    func start() {
        switch mode {
        case .pomodoro:
            startCountdown(.work, duration: TimeInterval(workMinutes * 60))
        case .stopwatch:
            startStopwatch()
        }
    }

    func pause() {
        switch state {
        case .running(.work), .running(.rest):
            pauseCountdown()
        case .running(.stopwatch):
            pauseStopwatch()
        default:
            break
        }
    }

    func resume() {
        switch state {
        case .paused(.work), .paused(.rest):
            resumeCountdown()
        case .paused(.stopwatch):
            resumeStopwatch()
        default:
            break
        }
    }

    func reset() {
        stopTicker()
        phaseEndDate = nil
        pausedRemaining = nil
        phaseStartDate = nil
        accumulatedElapsed = 0
        displayTime = 0
        totalForCurrentPhase = 0
        state = .idle
    }

    // MARK: - Pomodoro countdown

    private func startCountdown(_ phase: TimerPhase, duration: TimeInterval) {
        stopTicker()
        totalForCurrentPhase = duration
        phaseEndDate = Date().addingTimeInterval(duration)
        pausedRemaining = nil
        displayTime = duration
        state = .running(phase)
        startTicker()
    }

    private func pauseCountdown() {
        guard case .running(let phase) = state, let end = phaseEndDate else { return }
        let r = max(0, end.timeIntervalSinceNow)
        pausedRemaining = r
        displayTime = r
        stopTicker()
        state = .paused(phase)
    }

    private func resumeCountdown() {
        guard case .paused(let phase) = state, let pr = pausedRemaining else { return }
        phaseEndDate = Date().addingTimeInterval(pr)
        pausedRemaining = nil
        state = .running(phase)
        startTicker()
    }

    private func tickCountdown() {
        guard let end = phaseEndDate else { return }
        let r = max(0, end.timeIntervalSinceNow)
        displayTime = r
        if r <= 0 {
            complete()
        }
    }

    private func complete() {
        if playSoundOnComplete {
            NSSound.beep()
        }
        switch state {
        case .running(.work):
            startCountdown(.rest, duration: TimeInterval(breakMinutes * 60))
        case .running(.rest):
            reset()
        default:
            reset()
        }
    }

    // MARK: - Stopwatch count-up

    private func startStopwatch() {
        stopTicker()
        totalForCurrentPhase = 0
        phaseStartDate = Date()
        accumulatedElapsed = 0
        displayTime = 0
        state = .running(.stopwatch)
        startTicker()
    }

    private func pauseStopwatch() {
        guard case .running(.stopwatch) = state, let start = phaseStartDate else { return }
        accumulatedElapsed += Date().timeIntervalSince(start)
        phaseStartDate = nil
        displayTime = accumulatedElapsed
        stopTicker()
        state = .paused(.stopwatch)
    }

    private func resumeStopwatch() {
        guard case .paused(.stopwatch) = state else { return }
        phaseStartDate = Date()
        state = .running(.stopwatch)
        startTicker()
    }

    private func tickStopwatch() {
        guard let start = phaseStartDate else { return }
        displayTime = accumulatedElapsed + Date().timeIntervalSince(start)
    }

    // MARK: - Ticker

    private func tick() {
        switch state {
        case .running(.work), .running(.rest):
            tickCountdown()
        case .running(.stopwatch):
            tickStopwatch()
        default:
            break
        }
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        if let ticker {
            RunLoop.main.add(ticker, forMode: .common)
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}
