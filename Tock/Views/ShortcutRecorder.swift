import SwiftUI
import AppKit
import Carbon.HIToolbox

struct ShortcutRecorder: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    let onChange: (Int, Int) -> Void

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(displayText)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(isRecording ? Color.accentColor : .primary)
                .frame(minWidth: 110)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isRecording ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(isRecording ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(isRecording ? "Press a key combination, or Esc to cancel" : "Click to change shortcut")
        .onDisappear { stopRecording() }
    }

    private var displayText: String {
        if isRecording { return "Press shortcut…" }
        return KeyCodeFormatter.display(keyCode: keyCode, modifiers: modifiers)
    }

    private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handleKey(event)
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Esc with no modifiers cancels.
        if event.keyCode == UInt16(kVK_Escape) && flags.isEmpty {
            stopRecording()
            return nil
        }

        var carbonMods = 0
        if flags.contains(.command) { carbonMods |= cmdKey }
        if flags.contains(.shift) { carbonMods |= shiftKey }
        if flags.contains(.option) { carbonMods |= optionKey }
        if flags.contains(.control) { carbonMods |= controlKey }

        // Require at least one modifier so plain typing doesn't get bound.
        guard carbonMods != 0 else { return nil }

        let kc = Int(event.keyCode)
        keyCode = kc
        modifiers = carbonMods
        onChange(kc, carbonMods)
        stopRecording()
        return nil
    }
}
