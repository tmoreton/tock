import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        VStack(spacing: 14) {
            Picker("Mode", selection: $engine.mode) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(engine.isActive)

            RingTimerView(
                progress: engine.progress,
                displayTime: shownTime,
                color: engine.state.accentColor,
                phaseLabel: engine.state.displayName
            )
            .frame(width: 180, height: 180)

            ControlsView()

            Divider()

            HStack {
                Button {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Label("Settings…", systemImage: "gearshape")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .buttonStyle(.borderless)
            }
            .font(.callout)
        }
        .padding(20)
        .frame(width: 280)
        .background(engine.state.accentColor.opacity(0.08))
        .animation(.easeInOut(duration: 0.25), value: engine.state)
    }

    private var shownTime: TimeInterval {
        if engine.isActive { return engine.displayTime }
        switch engine.mode {
        case .pomodoro: return TimeInterval(engine.workMinutes * 60)
        case .stopwatch: return 0
        }
    }
}
