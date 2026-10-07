// The Helper shell: grabs the keys, asks core.swift what to do, then does it. That's all.
import AppKit
import Carbon.HIToolbox

let actionsFile = NSString(string: "~/.config/uwu/actions.json").expandingTildeInPath

// one fixed prefix, so `log stream` in guide.md can find us
func log(_ line: String) { NSLog("uwu: %@", line) }

// what wootility sends for each key, see the key table in guide.md
let keys: [(code: Int, key: Key)] = [(kVK_F13, .cycle), (kVK_F16, .action(1)), (kVK_F17, .action(2)), (kVK_F18, .action(3))]

// each supported terminal app's AppleScript by bundle id ( core.swift has the Cycle order ):
// list prints its Sessions in the listing format core.swift reads, focus moves keyboard focus to one Session
let scripts: [String: (list: String, focus: (String) -> String)] = [
    // `tab` is an iterm2 class in here, hence character id 9, and «property Indx» is the tab's index ( plain `index` errors )
    "com.googlecode.iterm2": (list: """
        set sep to character id 9
        tell application id "com.googlecode.iterm2"
            set out to ""
            repeat with w in windows
                set flags to ""
                if miniaturized of w then set flags to "minimized"
                if is hotkey window of w then set flags to flags & " dropdown"
                set wid to id of w
                repeat with t in tabs of w
                    set ti to «property Indx» of t
                    set pane to 0
                    repeat with s in sessions of t
                        set pane to pane + 1
                        set out to out & "session" & sep & wid & sep & ti & sep & pane & sep & (id of s) & sep & flags & linefeed
                    end repeat
                end repeat
            end repeat
            try
                set out to out & "current" & sep & (id of current session of current window) & linefeed
            end try
            return out
        end tell
        """,
        // select the Session, its tab AND its window, then activate, iterm2 needs every single one of those
        focus: { id in """
        tell application id "com.googlecode.iterm2"
            repeat with w in (get windows)
                repeat with t in (get tabs of w)
                    repeat with s in (get sessions of t)
                        if id of s is \(quoted(id)) then
                            select s
                            select t
                            select w
                            activate
                            return
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        """ }),
]

// the last terminal app you were in, so the Cycle key can take you back there from your browser
var lastTerminal: String?
NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { note in
    let app = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
    if let app, terminals.contains(app) { lastTerminal = app }
}

func pressed(_ key: Key) {
    var world = World()
    if key == .cycle {
        world.frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        world.lastTerminal = lastTerminal
        // ONLY ask apps that already run, AppleScript would happily launch the others
        // ponytail: an app that quits right between this check and the AppleScript gets launched again
        for app in terminals where !NSRunningApplication.runningApplications(withBundleIdentifier: app).isEmpty {
            world.listings[app] = applescript(scripts[app]!.list)
        }
    } else {
        // re-read on EVERY press, so edits apply right away
        world.actions = try? String(contentsOfFile: actionsFile, encoding: .utf8)
    }
    switch decide(key, world) {
    case .type(let text):
        log("\(key): typing \(text.count) characters") // never the text itself, it might be private
        type(text)
    case .run(let command):
        log("\(key): running \(command)")
        run(command)
    case .focus(let app, let session):
        log("\(key): focusing Session \(session) in \(app)")
        applescript(scripts[app]!.focus(session))
    case .activate(let app):
        log("\(key): back to \(app)")
        applescript("tell application id \(quoted(app)) to activate")
    case .nothing(let why):
        log("\(key): nothing, \(why)")
    }
}

// in-process, so the one-time Automation prompt asks about UwU Helper
// 2 seconds per Apple event instead of AppleScript's usual 2 minutes, a healthy terminal app answers WAY faster
// ponytail: runs on the main thread, so a hung terminal app still freezes every key, just for those 2 seconds a press,
// and the press that pops a one-time Automation prompt gives up before you click Allow, so you press again
@discardableResult
func applescript(_ source: String) -> String? {
    var error: NSDictionary?
    guard let script = NSAppleScript(source: "with timeout of 2 seconds\n\(source)\nend timeout") else { return nil }
    let result = script.executeAndReturnError(&error)
    if let error { log("AppleScript failed: \(error[NSAppleScript.errorMessage] ?? error)"); return nil }
    return result.stringValue
}

// ponytail: the ids come from the terminal app itself, so escaping " and \ is all the paranoia here
func quoted(_ text: String) -> String {
    "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
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
