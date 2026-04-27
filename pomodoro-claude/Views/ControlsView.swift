import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        HStack(spacing: 10) {
            switch engine.state {
            case .idle:
                Button {
                    engine.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.return, modifiers: [])
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(engine.state.accentColor == .gray ? .accentColor : engine.state.accentColor)

            case .running:
                Button {
                    engine.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.return, modifiers: [])
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(engine.state.accentColor)

                Button {
                    engine.reset()
                } label: {
                    Label("Reset", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)

            case .paused:
                Button {
                    engine.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.return, modifiers: [])
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(engine.state.currentPhase?.accentColor ?? .accentColor)

                Button {
                    engine.reset()
                } label: {
                    Label("Reset", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }
        }
    }
}
