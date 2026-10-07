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

        print(failed == 0 ? "all good" : "\(failed) FAILED")
        exit(failed == 0 ? 0 : 1)
    }
}
