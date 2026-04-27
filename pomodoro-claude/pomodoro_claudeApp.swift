import SwiftUI
import AppKit

@main
struct pomodoro_claudeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appDelegate.engine)
        } label: {
            MenuBarLabel()
                .environmentObject(appDelegate.engine)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.hotkeys)
        }
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        if engine.isActive {
            // Render to an NSImage so the menu bar honors the foreground color
            // instead of template-rendering the text in white/black.
            Image(nsImage: titleImage(text: formatTimer(engine.displayTime), color: nsTimerColor))
                .renderingMode(.original)
        } else {
            Image(systemName: "timer")
        }
    }

    private var nsTimerColor: NSColor {
        switch engine.state.currentPhase {
        case .work: return NSColor(red: 0.93, green: 0.27, blue: 0.27, alpha: 1)
        case .rest: return NSColor(red: 0.30, green: 0.69, blue: 0.45, alpha: 1)
        case .stopwatch: return NSColor(red: 0.20, green: 0.50, blue: 0.85, alpha: 1)
        case nil: return .labelColor
        }
    }

    private func titleImage(text: String, color: NSColor) -> NSImage {
        let font = NSFont.menuBarFont(ofSize: 0)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let textSize = attributed.size()
        let size = NSSize(width: ceil(textSize.width), height: ceil(textSize.height))
        let image = NSImage(size: size, flipped: false) { rect in
            attributed.draw(in: rect)
            return true
        }
        image.isTemplate = false
        return image
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = TimerEngine()
    let hotkeys = HotKeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeys.register(engine: engine)
    }
}
