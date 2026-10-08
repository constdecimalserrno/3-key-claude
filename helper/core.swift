// The Helper core: which key fired + a snapshot of the world in, exactly ONE effect out.
// Pure on purpose ( no files, no clocks, no AppKit ), so tests.swift can poke it without a Mac full of windows.
// The one peek at the disk it needs ( is that script there, is it executable ) comes in through World.file, tests hand it a fake one.
import Foundation

// the supported terminal apps by bundle id, in Cycle order
let terminals = ["com.googlecode.iterm2", "com.mitchellh.ghostty"]

enum Key: Equatable, CustomStringConvertible {
    case cycle
    case action(Int) // 1, 2, 3, left to right

    var description: String {
        switch self {
        case .cycle: return "Cycle key"
        case .action(let n): return "Action key \(n)"
        }
    }
}

// what's at a path on disk, as far as a script Action cares
enum File { case missing, plain, executable }

struct World {
    var actions: String? = nil // the Actions file text, nil when there is no file
    var listings: [String: String] = [:] // bundle id -> what its listing script printed, ONLY running terminal apps are in here
    var frontmost: String? = nil // bundle id of the frontmost app
    var lastTerminal: String? = nil // bundle id of the terminal app that was frontmost last
    var folder = "" // the folder holding the Actions file, relative script paths start there
    var home = "" // your home folder, for script paths starting with ~/
    var file: (String) -> File = { _ in .missing } // the shell's peek at the disk
}

enum Effect: Equatable {
    case type(String)
    case run(String)
    case script(runner: String?, path: String) // run the file with that runner, or as is when it's nil
    case focus(app: String, session: String) // bundle id, Session id
    case activate(String) // bundle id
    case nothing(String) // why, one line for the log
}

func decide(_ key: Key, _ world: World) -> Effect {
    switch key {
    case .cycle:
        return cycle(world)
    case .action(let n):
        guard let text = world.actions else {
            return .nothing("no Actions file at ~/.config/uwu/actions.json")
        }
        guard let list = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [Any] else {
            return .nothing("actions.json isn't a JSON list, look for a typo")
        }
        guard list.indices.contains(n - 1) else {
            return .nothing("actions.json has no entry \(n)")
        }
        // exactly one key, so {"type": "a", "run": "b"} can't quietly pick one
        if let entry = list[n - 1] as? [String: String], entry.count == 1 {
            if let text = entry["type"] { return .type(text) }
            if let command = entry["run"] { return .run(command) }
            if let path = entry["script"] { return script(path, world) }
        }
        return .nothing(#"entry \#(n) in actions.json must be {"type": "..."}, {"run": "..."} or {"script": "..."}"#)
    }
}

// a script Action: absolute, from your home folder ( ~/ ), or from the folder holding the Actions file
// ponytail: only YOUR ~, a ~someone/ path is just relative like any other
func script(_ path: String, _ world: World) -> Effect {
    let full = path.hasPrefix("/") ? path : path.hasPrefix("~/") ? world.home + path.dropFirst() : world.folder + "/" + path
    let file = world.file(full)
    if file == .missing { return .nothing("no script at \(full)") }
    if ["applescript", "scpt"].contains((full as NSString).pathExtension.lowercased()) { return .script(runner: "/usr/bin/osascript", path: full) }
    return file == .executable ? .script(runner: nil, path: full) : .script(runner: "/bin/sh", path: full)
}

// A listing is one line per Session plus one for the app's current Session, fields split by a tab:
//   session <window id> <tab index> <pane> <session id> <flags>
//   current <session id>
// flags are words, "minimized" or "dropdown" ( iterm2's hotkey window ) keep the Session out of the Cycle,
// ghostty never has any ( main.swift says why ).
// Lines that look like anything else are ignored.
func cycle(_ world: World) -> Effect {
    var sessions: [(app: String, id: String)] = []
    var current: String? // the frontmost app's current Session
    for app in terminals {
        var mine: [(window: String, tab: Int, pane: Int, id: String)] = []
        for line in (world.listings[app] ?? "").split(whereSeparator: \.isNewline) {
            let field = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            if field.count == 2, field[0] == "current", app == world.frontmost { current = field[1] }
            if field.count == 6, field[0] == "session", let tab = Int(field[2]), let pane = Int(field[3]),
               !field[5].split(separator: " ").contains(where: { $0 == "minimized" || $0 == "dropdown" }) {
                mine.append((field[1], tab, pane, field[4]))
            }
        }
        // by window id, NEVER the listing order: AppleScript lists windows front to back, and that reshuffles on every focus
        // .numeric puts integer ids in number order ( 9 before 10 ) and still gives text ids ( ghostty's ) a fixed one
        mine.sort { a, b in
            a.window != b.window ? a.window.compare(b.window, options: .numeric) == .orderedAscending : (a.tab, a.pane) < (b.tab, b.pane)
        }
        sessions += mine.map { (app, $0.id) }
    }
    guard let first = sessions.first else { return .nothing("no Sessions to cycle through") }
    if let frontmost = world.frontmost, terminals.contains(frontmost) {
        // its current Session isn't in the Cycle ( say you're in the hotkey window ), so start over
        guard let i = sessions.firstIndex(where: { $0.app == frontmost && $0.id == current }) else {
            return .focus(app: first.app, session: first.id)
        }
        let next = sessions[(i + 1) % sessions.count]
        return .focus(app: next.app, session: next.id)
    }
    // you're somewhere else, so first take you back to the terminal app you used last, if it still has Sessions
    if let last = world.lastTerminal, sessions.contains(where: { $0.app == last }) { return .activate(last) }
    return .focus(app: first.app, session: first.id)
}
