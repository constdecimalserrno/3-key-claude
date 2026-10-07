// The Helper core: which key fired + a snapshot of the world in, exactly ONE effect out.
// Pure on purpose ( no files, no clocks, no AppKit ), so tests.swift can poke it without a Mac full of windows.
import Foundation

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

struct World {
    var actions: String? // the Actions file text, nil when there is no file
}

enum Effect: Equatable {
    case type(String)
    case run(String)
    case nothing(String) // why, one line for the log
}

func decide(_ key: Key, _ world: World) -> Effect {
    switch key {
    case .cycle:
        return .nothing("the Cycle isn't built yet")
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
        }
        return .nothing(#"entry \#(n) in actions.json must be {"type": "..."} or {"run": "..."}"#)
    }
}
