// The Helper core: which key fired + a snapshot of the world in, exactly ONE effect out.
// Plus the Actions file both ways ( text to entries and back ) for the 3KC window.
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
        let item = entry(list[n - 1])
        switch item.kind {
        case .type: return .type(item.text)
        case .run: return .run(item.text)
        case .script: return script(item.text, world)
        case .odd: return .nothing(#"entry \#(n) in actions.json must be {"type": "..."}, {"run": "..."} or {"script": "..."}"#)
        }
    }
}

// one entry of the Actions file, the way decide() reads it and the 3KC window ( menubar.swift ) edits it
// odd is anything else ( say {"say": "hi"} or null ): text holds its JSON, so saving puts it back as it was
struct Entry: Equatable {
    enum Kind: String { case type, run, script, odd }
    var kind: Kind
    var text: String
}

// exactly one key, so {"type": "a", "run": "b"} can't quietly pick one
func entry(_ any: Any) -> Entry {
    if let pair = any as? [String: String], pair.count == 1, let only = pair.first,
       let kind = Entry.Kind(rawValue: only.key), kind != .odd {
        return Entry(kind: kind, text: only.value)
    }
    return Entry(kind: .odd, text: compact(any))
}

// the whole Actions file for the 3KC window: one entry per Action key at least ( a missing one becomes type nothing,
// which does nothing, same as before ), extra entries come along so saving keeps them.
// nil when it isn't a JSON list, the window leaves THAT file alone until you fix it by hand
func entries(_ text: String?) -> [Entry]? {
    let blank = Entry(kind: .type, text: "")
    guard let text else { return [blank, blank, blank] } // no file yet, saving makes one
    guard let list = (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [Any] else { return nil }
    return list.map(entry) + Array(repeating: blank, count: max(0, 3 - list.count))
}

// and back again: one entry per line, in key order, written the same way every time, so your Actions file stays diffable
func json(_ entries: [Entry]) -> String {
    let lines = entries.map { $0.kind == .odd ? $0.text : "{\(compact($0.kind.rawValue)): \(compact($0.text))}" }
    return "[\n  " + lines.joined(separator: ",\n  ") + "\n]\n"
}

// one line of JSON: " and \\ escaped, / and ü left alone, keys sorted so an odd entry never reshuffles
func compact(_ any: Any) -> String {
    (try? JSONSerialization.data(withJSONObject: any, options: [.fragmentsAllowed, .sortedKeys, .withoutEscapingSlashes]))
        .flatMap { String(data: $0, encoding: .utf8) } ?? "null"
}

// a file you picked, written the shortest way script() still finds it: from the Actions folder, from ~/, or the whole path
func shorten(_ path: String, _ world: World) -> String {
    if !world.folder.isEmpty, path.hasPrefix(world.folder + "/") { return String(path.dropFirst(world.folder.count + 1)) }
    if !world.home.isEmpty, path.hasPrefix(world.home + "/") { return "~" + path.dropFirst(world.home.count) }
    return path
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
