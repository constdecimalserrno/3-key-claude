// The Helper shell: grabs the keys, asks core.swift what to do, then does it. That's all.
import AppKit
import Carbon.HIToolbox

let actionsFile = NSString(string: "~/.config/uwu/actions.json").expandingTildeInPath

// one fixed prefix, so `log stream` in guide.md can find us
func log(_ line: String) { NSLog("uwu: %@", line) }

// what wootility sends for each key, see the key table in guide.md
let keys: [(code: Int, key: Key)] = [(kVK_F13, .cycle), (kVK_F16, .action(1)), (kVK_F17, .action(2)), (kVK_F18, .action(3))]

func pressed(_ key: Key) {
    // re-read on EVERY press, so edits apply right away
    let world = World(actions: try? String(contentsOfFile: actionsFile, encoding: .utf8))
    switch decide(key, world) {
    case .type(let text):
        log("\(key): typing \(text.count) characters") // never the text itself, it might be private
        type(text)
    case .run(let command):
        log("\(key): running \(command)")
        run(command)
    case .nothing(let why):
        log("\(key): nothing, \(why)")
    }
}

// ponytail: virtual key 0 plus a Unicode string, so an app that reads raw key codes instead of text sees the A key
func type(_ text: String) {
    guard AXIsProcessTrusted() else { return log("can't type without Accessibility, tick UwU Helper in System Settings") }
    let source = CGEventSource(stateID: .privateState)
    for character in text {
        let units = Array(String(character).utf16)
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: down)
            event?.flags = [] // a held Talk key ( Right Ctrl ) must NOT turn "yes" into ctrl-y-e-s
            event?.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            event?.post(tap: .cgSessionEventTap)
        }
    }
}

// ponytail: launchd's PATH is only /usr/bin:/bin:/usr/sbin:/sbin, anything else needs its full path
func run(_ command: String) {
    do { _ = try Process.run(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", command]) } // fire-and-forget
    catch { log("couldn't run \(command): \(error)") }
}

// Carbon hotkeys need no Accessibility and no Input Monitoring
var pressedSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
    var id = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                      nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
    pressed(keys[Int(id.id)].key)
    return noErr
}, 1, &pressedSpec, nil, nil)

// bare, or with ONE modifier held, so the keys still fire while you hold the Talk key
// ponytail: two modifiers at once ( say ctrl + shift ) and the key does nothing
for (index, entry) in keys.enumerated() {
    for modifiers in [0, controlKey, optionKey, shiftKey, cmdKey] {
        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: OSType(0x7577_7521), id: UInt32(index)) // "uwu!"
        let status = RegisterEventHotKey(UInt32(entry.code), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref)
        if status != noErr { log("couldn't grab the \(entry.key) ( error \(status), does another app own it? )") }
    }
}

if !AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) {
    log("no Accessibility yet, tick UwU Helper in System Settings so the Action keys can type")
}
log("up and listening")
NSApplication.shared.run() // LSUIElement in Info.plist keeps us out of the Dock and the menu bar
