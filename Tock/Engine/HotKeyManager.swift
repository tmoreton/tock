import AppKit
import Carbon.HIToolbox
import Combine

@MainActor
final class HotKeyManager: ObservableObject {
    static let defaultKeyCode: Int = kVK_ANSI_P
    static let defaultModifiers: Int = controlKey | optionKey | cmdKey

    static let keyCodeDefaultsKey = "hotkeyKeyCode"
    static let modifiersDefaultsKey = "hotkeyModifiers"

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    fileprivate weak var engine: TimerEngine?

    func register(engine: TimerEngine) {
        guard self.engine == nil else { return }
        self.engine = engine
        installEventHandler()
        let keyCode = UserDefaults.standard.object(forKey: Self.keyCodeDefaultsKey) as? Int ?? Self.defaultKeyCode
        let modifiers = UserDefaults.standard.object(forKey: Self.modifiersDefaultsKey) as? Int ?? Self.defaultModifiers
        registerHotKey(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers))
    }

    func update(keyCode: Int, modifiers: Int) {
        unregisterHotKey()
        registerHotKey(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers))
    }

    private func installEventHandler() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func registerHotKey(keyCode: UInt32, modifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x706F6D6F), id: 1)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}

nonisolated private func hotKeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return noErr }
    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        manager.engine?.toggle()
    }
    return noErr
}
