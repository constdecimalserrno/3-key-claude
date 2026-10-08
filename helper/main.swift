// The Helper shell: grabs the keys, asks core.swift what to do, then does it. That's all ( setup.swift has the Setup window, menubar.swift the rest you can see ).
import AppKit
import Carbon.HIToolbox
import ServiceManagement

let uwuFolder = NSString(string: "~/.config/uwu").expandingTildeInPath
let actionsFile = uwuFolder + "/actions.json"

// one fixed prefix, so the log command in guide.md can find us
func log(_ line: String) { NSLog("uwu: %@", line) }

// `3-key Claude.app/Contents/MacOS/3KeyClaude --uninstall` only takes us out of the login items,
// install.sh uninstall does the rest
if CommandLine.arguments.contains("--uninstall") {
    do { try SMAppService.mainApp.unregister(); log("out of the login items, bye") }
    catch { log("couldn't leave the login items: \(error)") }
    exit(0)
}

// still inside the mounted .dmg, or Gatekeeper runs a temporary copy of us: NO login item and NO Actions file from there
// ponytail: an Applications folder on an external disk lives under /Volumes too, so that gets the same telling-off
if Bundle.main.bundlePath.hasPrefix("/Volumes/") || Bundle.main.bundlePath.contains("/AppTranslocation/") { dragMeFirst() }

// ONE of us is plenty, two would fight over the keys ( the old UwU Helper counts, it has the same bundle id )
if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "").contains(where: { $0.processIdentifier != getpid() }) {
    log("already running, bye")
    exit(0)
}

// start at login, so dragging us into Applications and opening us once is the whole install
// ponytail: the old LaunchAgent brought us back after a crash, a login item doesn't, the next login or a double-click does
if SMAppService.mainApp.status != .enabled {
    do { try SMAppService.mainApp.register(); log("starting at login from now on") }
    catch { log("couldn't add us to the login items: \(error)") }
}

// no Actions file or examples folder yet? copy the ones that ship inside the app, then they're yours to edit, NEVER overwritten
// ponytail: the whole examples folder or nothing, so a new example in an update only shows up once you delete yours
for name in ["actions.json", "examples"] {
    let mine = uwuFolder + "/" + name
    guard !FileManager.default.fileExists(atPath: mine), let shipped = Bundle.main.resourceURL?.appendingPathComponent(name).path else { continue }
    do {
        try FileManager.default.createDirectory(atPath: uwuFolder, withIntermediateDirectories: true)
        try FileManager.default.copyItem(atPath: shipped, toPath: mine)
        log("put \(name) at ~/.config/uwu/\(name), make it yours!")
    } catch { log("couldn't put \(name) at ~/.config/uwu/\(name): \(error)") }
}

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
    // ghostty 1.3+ has windows, tabs and terminals, but no minimized or quick terminal property:
    // its quick terminal is a panel, and panels never show up in `windows`, so it stays out of the Cycle all by itself
    // ponytail: minimized windows DO show up and nothing says they're minimized, so the Cycle visits them and pops them back up
    "com.mitchellh.ghostty": (list: """
        set sep to character id 9
        tell application id "com.mitchellh.ghostty"
            set out to ""
            repeat with w in windows
                set wid to id of w
                repeat with t in tabs of w
                    set ti to index of t
                    set pane to 0
                    repeat with s in terminals of t
                        set pane to pane + 1
                        set out to out & "session" & sep & wid & sep & ti & sep & pane & sep & (id of s) & sep & linefeed
                    end repeat
                end repeat
            end repeat
            try
                set out to out & "current" & sep & (id of focused terminal of selected tab of front window) & linefeed
            end try
            return out
        end tell
        """,
        // focus picks the terminal's split, its tab AND its window in one go, activate does the rest
        focus: { id in """
        tell application id "com.mitchellh.ghostty"
            focus terminal id \(quoted(id))
            activate
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
    // the Setup window is open, so the key only ticks its box in there, no cycling, no typing
    if Setup.shared.isOpen { return Setup.shared.saw(key.description) }
    // re-read on EVERY press, so edits apply right away
    if key != .cycle { return act(decide(key, actionWorld(try? String(contentsOfFile: actionsFile, encoding: .utf8))), key) }
    var world = World()
    world.frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    world.lastTerminal = lastTerminal
    // ONLY ask apps that already run, AppleScript would happily launch the others
    // ponytail: an app that quits right between this check and the AppleScript gets launched again
    for app in terminals where !NSRunningApplication.runningApplications(withBundleIdentifier: app).isEmpty {
        world.listings[app] = applescript(scripts[app]!.list)
    }
    act(decide(key, world), key)
}

// what an Action key needs to know: the Actions file text ( the real one, or the 3KC window's unsaved one for Test ) and a peek at the disk
func actionWorld(_ actions: String?) -> World {
    World(actions: actions, folder: uwuFolder, home: NSHomeDirectory()) { path in
        var folder: ObjCBool = false // a folder is no script, so it counts as missing
        guard FileManager.default.fileExists(atPath: path, isDirectory: &folder), !folder.boolValue else { return .missing }
        return FileManager.default.isExecutableFile(atPath: path) ? .executable : .plain
    }
}

func act(_ effect: Effect, _ key: Key) {
    switch effect {
    case .type(let text):
        log("\(key): typing \(text.count) characters") // never the text itself, it might be private
        type(text)
    case .run(let command):
        log("\(key): running \(command)")
        launch("/bin/sh", ["-c", command])
    case .script(let runner, let path):
        log("\(key): running \(path)" + (runner.map { " with \($0)" } ?? ""))
        if let runner { launch(runner, [path]) } else { launch(path, []) }
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

// in-process, so the one-time Automation prompt asks about 3-key Claude
// 2 seconds per Apple event instead of AppleScript's usual 2 minutes, a healthy terminal app answers WAY faster
// ponytail: runs on the main thread, so a hung terminal app still freezes every key, just for those 2 seconds a press,
// and the press that pops a one-time Automation prompt gives up before you click Allow ( the Setup window asks with a minute )
@discardableResult
func applescript(_ source: String, timeout: Int = 2) -> String? {
    var error: NSDictionary?
    guard let script = NSAppleScript(source: "with timeout of \(timeout) seconds\n\(source)\nend timeout") else { return nil }
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
    guard AXIsProcessTrusted() else { return log("can't type without Accessibility, tick 3-key Claude in System Settings") }
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

// fire-and-forget, for run and script Actions alike
// ponytail: launchd's PATH is only /usr/bin:/bin:/usr/sbin:/sbin, anything else needs its full path
// ponytail: an executable script without a #! line fails right here, and the log says so
func launch(_ program: String, _ arguments: [String]) {
    do { _ = try Process.run(URL(fileURLWithPath: program), arguments: arguments) }
    catch { log("couldn't run \(program): \(error)") }
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

// the Setup window has its own Accessibility step, so macOS's own prompt only shows up once you're past it ( say after an update )
if !AXIsProcessTrusted() {
    log("no Accessibility yet, tick 3-key Claude in System Settings so the Action keys can type")
    if Setup.shared.done { AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) }
}
log("up and listening")
NSApplication.shared.delegate = Setup.shared // puts up the menu bar icon, and the Setup window on first launch
NSApplication.shared.run() // LSUIElement in Info.plist keeps us out of the Dock, the menu bar icon is all you see ( menubar.swift )
