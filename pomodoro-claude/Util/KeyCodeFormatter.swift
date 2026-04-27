import Foundation
import AppKit
import Carbon.HIToolbox

enum KeyCodeFormatter {
    static func display(keyCode: Int, modifiers: Int) -> String {
        let mods = modifierGlyphs(modifiers)
        let key = keyGlyph(keyCode) ?? "?"
        return mods + key
    }

    static func modifierGlyphs(_ modifiers: Int) -> String {
        var s = ""
        if modifiers & controlKey != 0 { s += "⌃" }
        if modifiers & optionKey != 0 { s += "⌥" }
        if modifiers & shiftKey != 0 { s += "⇧" }
        if modifiers & cmdKey != 0 { s += "⌘" }
        return s
    }

    static func keyGlyph(_ keyCode: Int) -> String? {
        switch keyCode {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            return characterFromKeyboardLayout(keyCode: keyCode)
        }
    }

    private static func characterFromKeyboardLayout(keyCode: Int) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let layoutDataPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let dataRef = Unmanaged<CFData>.fromOpaque(layoutDataPtr).takeUnretainedValue()
        guard let bytes = CFDataGetBytePtr(dataRef) else { return nil }

        return bytes.withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { layoutPtr in
            var deadKeyState: UInt32 = 0
            let maxChars = 4
            var chars = [UniChar](repeating: 0, count: maxChars)
            var actualLength = 0
            let status = UCKeyTranslate(
                layoutPtr,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                maxChars,
                &actualLength,
                &chars
            )
            guard status == noErr, actualLength > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: actualLength).uppercased()
        }
    }
}
