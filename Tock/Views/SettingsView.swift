import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var hotkeys: HotKeyManager
    @StateObject private var launchAtLogin = LaunchAtLogin()

    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("playSoundOnComplete") private var playSoundOnComplete: Bool = true

    @AppStorage(HotKeyManager.keyCodeDefaultsKey) private var hotkeyKeyCode: Int = HotKeyManager.defaultKeyCode
    @AppStorage(HotKeyManager.modifiersDefaultsKey) private var hotkeyModifiers: Int = HotKeyManager.defaultModifiers

    var body: some View {
        Form {
            Section {
                Stepper(value: $workMinutes, in: 1...120) {
                    LabeledContent("Focus duration", value: "\(workMinutes) min")
                }
                Stepper(value: $breakMinutes, in: 1...60) {
                    LabeledContent("Break duration", value: "\(breakMinutes) min")
                }
            } header: {
                Text("Durations")
            } footer: {
                Text("Duration changes apply on the next phase.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Sound") {
                Toggle("Play sound on completion", isOn: $playSoundOnComplete)
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                ))
            } header: {
                Text("Startup")
            } footer: {
                Text("Tock will start automatically when you log in to your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Start / Pause") {
                    ShortcutRecorder(
                        keyCode: $hotkeyKeyCode,
                        modifiers: $hotkeyModifiers
                    ) { kc, m in
                        hotkeys.update(keyCode: kc, modifiers: m)
                    }
                }
                Button("Reset to default") {
                    hotkeyKeyCode = HotKeyManager.defaultKeyCode
                    hotkeyModifiers = HotKeyManager.defaultModifiers
                    hotkeys.update(
                        keyCode: HotKeyManager.defaultKeyCode,
                        modifiers: HotKeyManager.defaultModifiers
                    )
                }
            } header: {
                Text("Hotkey")
            } footer: {
                Text("Click the shortcut, press a new key combination (with at least one modifier), or press Esc to cancel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 480)
        .onAppear { launchAtLogin.refresh() }
    }
}
