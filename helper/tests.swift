// Pokes the Helper core with fake worlds and checks the ONE effect it picks.
// Run it with ./install.sh test, it exits non-zero when anything fails.
import Foundation

@main
enum Tests {
    static var failed = 0

    static func expect(_ name: String, _ got: Effect, _ want: Effect) {
        var ok = got == want
        // for "nothing", any reason will do as long as it's one line for the log
        if case .nothing(let why) = got, case .nothing = want { ok = !why.isEmpty && !why.contains("\n") }
        if !ok { failed += 1 }
        print(ok ? "ok    \(name)" : "FAIL  \(name): got \(got), want \(want)")
    }

    static func main() {
        let nothing = Effect.nothing("")

        // the default Actions file that ships in helper/actions.json
        let defaults = World(actions: try? String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8))
        expect("default Action 1 opens a new iterm2 window", decide(.action(1), defaults),
               .run(#"osascript -e 'tell application "iTerm" to create window with default profile' -e 'tell application "iTerm" to activate'"#))
        expect("default Action 2 types yes, no Return", decide(.action(2), defaults), .type("yes"))
        expect("default Action 3 types no, no Return", decide(.action(3), defaults), .type("no"))

        // your own Actions
        let mine = World(actions: #"[{"run": "say uwu"}, {"type": "ünïcödé ok"}, {"type": ""}, {"type": "a fourth one is ignored"}]"#)
        expect("run", decide(.action(1), mine), .run("say uwu"))
        expect("type arrives exactly", decide(.action(2), mine), .type("ünïcödé ok"))
        expect("type nothing at all", decide(.action(3), mine), .type(""))

        // missing
        expect("missing Actions file", decide(.action(1), World(actions: nil)), nothing)

        // malformed file
        for (name, text) in [
            ("empty file", ""),
            ("not JSON", "yes please"),
            ("missing bracket", #"[{"type": "yes"}"#),
            ("object instead of a list", #"{"type": "yes"}"#),
            ("just a string", #""yes""#),
        ] {
            expect("malformed: \(name)", decide(.action(1), World(actions: text)), nothing)
        }

        // malformed entry
        for (name, text) in [
            ("number instead of text", #"[{"type": 1}]"#),
            ("unknown key", #"[{"say": "hi"}]"#),
            ("both type and run", #"[{"type": "a", "run": "b"}]"#),
            ("plain string", #"["yes"]"#),
            ("null", "[null]"),
            ("empty object", "[{}]"),
        ] {
            expect("malformed entry: \(name)", decide(.action(1), World(actions: text)), nothing)
        }

        // out of range
        let one = World(actions: #"[{"type": "yes"}]"#)
        expect("only one entry, Action 1 still works", decide(.action(1), one), .type("yes"))
        expect("only one entry, Action 2 does nothing", decide(.action(2), one), nothing)
        expect("only one entry, Action 3 does nothing", decide(.action(3), one), nothing)
        expect("empty list", decide(.action(1), World(actions: "[]")), nothing)
        expect("Action 0 does nothing", decide(.action(0), defaults), nothing)

        // the Cycle
        let iterm = "com.googlecode.iterm2", safari = "com.apple.Safari"
        func focus(_ id: String) -> Effect { .focus(app: iterm, session: id) }
        // a Session line, the way the iterm2 listing script in main.swift prints it
        func session(_ window: String, _ tab: Int, _ pane: Int, _ id: String, _ flags: String = "") -> String {
            ["session", window, "\(tab)", "\(pane)", id, flags].joined(separator: "\t")
        }
        func listing(_ lines: [String], current: String? = nil) -> String {
            (lines + (current.map { ["current\t\($0)"] } ?? [])).joined(separator: "\n")
        }
        func cycle(_ lines: [String], current: String? = nil, frontmost: String? = iterm, last: String? = nil) -> Effect {
            decide(.cycle, World(listings: [iterm: listing(lines, current: current)], frontmost: frontmost, lastTerminal: last))
        }

        // front to back, the way iterm2 lists windows: 30 is in front, A B C D E is the Cycle
        let windows = [
            session("30", 0, 1, "E"),
            session("7", 1, 1, "C"),
            session("7", 0, 1, "A"),
            session("7", 0, 2, "B"),
            session("12", 0, 1, "D"),
        ]
        // focusing reshuffles the front-to-back order, the Cycle must NOT care
        for (order, lines) in [("front to back", windows), ("reshuffled", windows.reversed())] {
            for (from, to) in [("A", "B"), ("B", "C"), ("C", "D"), ("D", "E")] {
                expect("\(order): \(from) to \(to)", cycle(lines, current: from), focus(to))
            }
            expect("\(order): wraps from E back to A", cycle(lines, current: "E"), focus("A"))
        }
        expect("current Session missing from the listing", cycle(windows, current: "gone"), focus("A"))
        expect("no current Session at all", cycle(windows), focus("A"))

        // skipped windows, even with the lowest ids
        let skipped = [
            session("1", 0, 1, "M", "minimized"),
            session("2", 0, 1, "H", " dropdown"),
            session("3", 0, 1, "MH", "minimized dropdown"),
            session("5", 0, 1, "X"),
            session("5", 0, 2, "Y"),
        ]
        expect("minimized and hotkey windows skipped", cycle(skipped, frontmost: safari), focus("X"))
        expect("wraps past the skipped windows", cycle(skipped, current: "Y"), focus("X"))
        expect("from the hotkey window to the first Session", cycle(skipped, current: "H"), focus("X"))

        // starting from a non-terminal app
        expect("back to the last terminal app", cycle(windows, current: "C", frontmost: safari, last: iterm), .activate(iterm))
        expect("no last terminal app, first Session", cycle(windows, current: "C", frontmost: safari), focus("A"))
        expect("last terminal app not running anymore, first Session",
               cycle(windows, current: "C", frontmost: safari, last: "com.mitchellh.ghostty"), focus("A"))
        expect("no frontmost app at all, first Session", cycle(windows, frontmost: nil), focus("A"))

        // nothing to do
        expect("no Sessions", cycle([], frontmost: safari, last: iterm), nothing)
        expect("no Sessions while in iterm2", cycle([]), nothing)
        expect("only skipped Sessions", cycle(Array(skipped.prefix(3)), current: "H"), nothing)
        expect("iterm2 not running", decide(.cycle, World(frontmost: safari, lastTerminal: iterm)), nothing)
        expect("junk listing", cycle(["execution error: not authorized", "session\t1\tx\t1\tA\t"]), nothing)

        // ghostty: text window ids, no flags ever, and its Sessions come after iterm2's
        let ghostty = "com.mitchellh.ghostty"
        func ghost(_ id: String) -> Effect { .focus(app: ghostty, session: id) }
        // front to back again, a tab group with a split in tab 1, plus a lone window: G1 G2 G3 G4 is the Cycle
        let ghosts = [
            session("window-6000037b2c80", 1, 1, "G4"),
            session("tab-group-600003a1e540", 2, 1, "G3"),
            session("tab-group-600003a1e540", 1, 2, "G2"),
            session("tab-group-600003a1e540", 1, 1, "G1"),
        ]
        func both(frontmost: String?, last: String? = nil, itermCurrent: String? = "C", ghosttyCurrent: String? = "G3") -> Effect {
            decide(.cycle, World(listings: [iterm: listing(windows, current: itermCurrent), ghostty: listing(ghosts, current: ghosttyCurrent)],
                                 frontmost: frontmost, lastTerminal: last))
        }

        // only ghostty running
        for (order, lines) in [("front to back", ghosts), ("reshuffled", ghosts.reversed())] {
            for (from, to) in [("G1", "G2"), ("G2", "G3"), ("G3", "G4"), ("G4", "G1")] {
                expect("only ghostty, \(order): \(from) to \(to)",
                       decide(.cycle, World(listings: [ghostty: listing(lines, current: from)], frontmost: ghostty)), ghost(to))
            }
        }
        expect("only ghostty, from a browser, first ghostty Session",
               decide(.cycle, World(listings: [ghostty: listing(ghosts, current: "G3")], frontmost: safari)), ghost("G1"))

        // both, and ONLY the frontmost app's current Session counts
        expect("both, in iterm2: C to D", both(frontmost: iterm), focus("D"))
        expect("both, in iterm2: last iterm2 Session E on to ghostty G1", both(frontmost: iterm, itermCurrent: "E"), ghost("G1"))
        expect("both, in ghostty: G3 to G4", both(frontmost: ghostty), ghost("G4"))
        expect("both, in ghostty: wraps from G4 back to iterm2 A", both(frontmost: ghostty, ghosttyCurrent: "G4"), focus("A"))
        expect("both, in ghostty with no current Session, first Session", both(frontmost: ghostty, ghosttyCurrent: nil), focus("A"))

        // from a non-terminal app
        expect("both, from a browser, back to ghostty", both(frontmost: safari, last: ghostty), .activate(ghostty))
        expect("both, from a browser, back to iterm2", both(frontmost: safari, last: iterm), .activate(iterm))
        expect("ghostty was last but has no Sessions now ( say only its quick terminal ), first iterm2 Session",
               decide(.cycle, World(listings: [iterm: listing(windows), ghostty: ""], frontmost: safari, lastTerminal: ghostty)), focus("A"))
        expect("ghostty frontmost with no Sessions, first iterm2 Session",
               decide(.cycle, World(listings: [iterm: listing(windows, current: "C"), ghostty: ""], frontmost: ghostty)), focus("A"))
        expect("both running, no Sessions anywhere",
               decide(.cycle, World(listings: [iterm: "", ghostty: ""], frontmost: safari, lastTerminal: ghostty)), nothing)

        print(failed == 0 ? "all good" : "\(failed) FAILED")
        exit(failed == 0 ? 0 : 1)
    }
}
