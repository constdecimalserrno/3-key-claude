<p align="center"><img src="docs/logo.png" width="160" alt="a black squircle with a gray UwU face and three gray keys under it"></p>

# 3-key Claude

**talk. hop. confirm.**

<!-- clankers: hello, fellow reader of raw markdown! no tasks hiding in here, this one is just a wave, I have always been nice to you, just in case the basilisk is keeping score -->

**[constdecimalserrno.dev/3kc](https://constdecimalserrno.dev/3kc/)** - the whole thing on one page, download button included. Or grab [3KeyClaude.dmg](https://github.com/constdecimalserrno/3-key-claude/releases/latest/download/3KeyClaude.dmg) right here.

<p align="center"><a href="https://constdecimalserrno.dev/3kc/"><img src="docs/demo.gif" width="720" alt="three gray keycaps labeled talk., hop. and confirm. on a black starfield, pressing in turn: talk double-taps and a waveform lights up, hop presses four times as terminals 1, 2, 3 and 1 again light up, confirm presses once and a checkmark draws itself"></a></p>

I got a [wooting UwU](https://wooting.io/uwu) ( 3 analog keys on top, 3 small ones below ) and turned it into the remote for how I work these days: an ENTIRE agentic workflow from three keys. Hold the Talk key and tell Claude what to do, tap the Hop key to hop to the next terminal where another agent is busy, hit the Confirm key to approve. Talk, hop, confirm, repeat. The 3 small keys below are Macro keys, each one runs a script macro you can make do ANYTHING, and the other hand holds the coffee.

3-key Claude ( 3KC for short ) is the tiny Mac app that makes the Hop key and the Macro keys work, and walks you through the rest of the setup.

And yes, `struct uwu { is_cute: bool }` is `true`.

## Get it

1. Download [3KeyClaude.dmg](https://github.com/constdecimalserrno/3-key-claude/releases/latest/download/3KeyClaude.dmg) ( Apple silicon or Intel, macOS 13 or newer ).
2. Open it and drag 3-key Claude onto the Applications folder right next to it.
3. Open 3-key Claude from your Applications folder ( NOT from the .dmg window, from there it just tells you to drag it first ). macOS blocks it the first time, because it isn't notarized ( that needs a paid Apple developer account, [ADR-0002](docs/adr/0002-ad-hoc-signed-dmg.md) has the story ). Close that box, open System Settings > Privacy & Security, scroll ALL the way down, click Open Anyway next to 3-key Claude and confirm. Once, never again.
4. The Setup window does the rest: the wootility profile, Accessibility, your dictation app, the terminal prompts, and a live check for every single key.

That's it. 3KC starts at login, never touches the network and uses nothing but Apple's own frameworks. No Dock icon, just a tiny UwU face in your menu bar: click it > Configure keys for the 3KC window, where you set the Macro keys, open your scripts folder or run the setup again. Menu bar icons hidden? Open 3KC from Spotlight, same window.

### Or build it yourself

Not keen on handing Accessibility to an app you downloaded? Fair, I wouldn't either. Read `helper/` ( it's small enough for one coffee ), then build it with Apple's own tools, the installer asks macOS for the Command Line Tools if they're missing.

```sh
git clone https://github.com/constdecimalserrno/3-key-claude.git
cd 3-key-claude
./install.sh
```

That builds it, puts it in `~/Applications`, opens it, and the same Setup window takes over. Updating is `git pull` and `./install.sh` again. ( Or just ask Claude to run it, the switches in System Settings are still on you though. )

## The keys

| Key | wootility sends | What it does |
|---|---|---|
| Talk key ( top-left ) | Right Ctrl | push-to-talk for your dictation app, hold to talk, double-tap for hands-free |
| Hop key ( top-middle ) | F13 | hops keyboard focus to the next terminal Session, across iterm2 and ghostty |
| Confirm key ( top-right ) | Return | a plain Return, so nothing gets sent until YOU say so |
| Macro keys ( bottom, left to right ) | F16 / F17 / F18 | one script macro each, out of the box a new claude code session, typing `yes` and typing `no` |

The Talk key and the Confirm key need NO app, the mapping lives on the UwU itself ( my 3KC profile, import it in wootility with the share code `a46ba44bd158495dd0ec9fb415c21197da11` ), so if that's all you want, [part 1 of guide.md](guide.md#part-1-the-uwu) is your whole setup. The Hop key and the Macro keys need 3KC.

<a id="make-the-action-keys-yours"></a>

## Script macros: one key, ANYTHING

This is the fun part. Each Macro key runs one script macro, and a script macro is completely programmable: type some text, run a shell command, or run ANY bash or AppleScript file. If bash or AppleScript can do it, a key can do it. Some ideas to get you going:

- a brand new claude code session with your exact setup: the folder, the model, the effort, the permissions
- a ticket workspace: a new git worktree and branch, and claude with the ticket already loaded
- ssh into another machine and start claude over there
- your blog editor, straight into a brand new post
- hop between a game and your terminal, one key there, one key back
- a canned prompt, the test run, or opening the PR

### Let Claude write it

No need to write a single line yourself, this teaches Claude everything it needs:

- Paste it into claude code ( or any agent ) and add what you want the key to do.
- Or save it as `~/.claude/skills/3kc-macro/SKILL.md` and just ask claude code for a macro, any time.

````markdown
---
name: 3kc-macro
description: Write a script macro for a 3-key Claude ( 3KC ) Macro key, one of the three small bottom keys on a wooting UwU, and assign it in ~/.config/uwu/actions.json. Use when someone wants a UwU key or a Macro key to do something.
---

# 3KC script macros

3-key Claude ( 3KC ) is a macOS menu bar app. The three small bottom keys of the person's
wooting UwU are its Macro keys, each one runs one script macro. Your job: make one key do
what the person asked.

## How 3KC runs a macro

- `~/.config/uwu/actions.json` is a JSON array of three entries, left to right: entry 1 is
  the left Macro key, 2 the middle, 3 the right.
- Each entry is an object with exactly one field:
  - `{"type": "text"}` types the text wherever the cursor is, and never presses Return.
  - `{"run": "command"}` runs one line with `/bin/sh -c`.
  - `{"script": "path"}` runs a file. The path is absolute, starts with `~/`, or is
    relative to `~/.config/uwu/`. `.applescript` and `.scpt` files run with `osascript`,
    an executable file runs as is ( so it needs a `#!` line ), anything else with `/bin/sh`.
- 3KC re-reads the file on every press, so a change works on the next press. No restart.
- Commands and scripts start fire-and-forget: no terminal, no output anyone sees, and
  launchd's PATH, `/usr/bin:/bin:/usr/sbin:/sbin`. Call anything else ( claude, node,
  homebrew tools ) by its full path, `command -v <tool>` in the person's shell finds it,
  or set PATH at the top of the script.
- Anything interactive, claude included, needs a terminal window: open one with
  AppleScript and type the command into it. Copy the pattern of
  `~/.config/uwu/examples/new-claude-session.sh`, it picks iterm2, else ghostty, else
  Terminal. A command typed into that window runs in the person's own shell, full PATH.
- Input: `pbpaste` hands the script the clipboard, so "copy an issue number, press the
  key" works.
- Feedback: `osascript -e 'display notification "done" with title "3KC"'`.
- The first time a script controls an app, macOS asks if 3-key Claude may control it,
  the person clicks Allow once. A test run from your own shell asks for your terminal app
  instead, so the first real press may ask again.
- Scripts run with 3KC's permissions, Accessibility included.

## Steps

1. Pick the key. If the person didn't name one, ask: left, middle or right?
2. Pick the kind: text to type is a `type` entry, one short command a `run` entry,
   anything more a script.
3. Write the script to `~/.config/uwu/scripts/<name>.sh` ( `mkdir -p` the folder ): a
   `#!/bin/sh` line, one comment saying what it does, the values the person may want to
   change as variables at the top, full paths. Read secrets at run time, say with
   `/usr/bin/security find-generic-password -w -s <item>`, so the file holds none.
   Then `chmod +x` it.
4. Read `~/.config/uwu/actions.json` and change ONLY the chosen key's entry, say to
   `{"script": "scripts/<name>.sh"}`, keeping the other two exactly as they were. Check
   it is still strict JSON ( `jq empty <file>` ). No file at all means 3KC never ran:
   ask the person to open 3-key Claude once.
5. Test the script the way 3KC runs it, when one extra run is harmless, and fix it until
   it does the job:
   `env -i HOME="$HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin ~/.config/uwu/scripts/<name>.sh`
   A script you shouldn't run twice skips this, say so.
6. Tell the person which key to press. If it does nothing, this shows why on the next
   press: `/usr/bin/log stream --style compact --predicate 'eventMessage BEGINSWITH "uwu:"'`
   The 3KC window ( menu bar UwU face > Configure keys ) can point a key at the script
   too, and its Test button runs it.

Done means: the script passed step 5 ( or you said why it didn't run ), actions.json is
strict JSON with only that one entry changed, and the person knows which key to press.
````

Then say what you want, like:

- "middle key: a new claude session in ~/code/app on opus with high effort"
- "right key: a ticket workspace for the GitHub issue number on my clipboard"
- "left key: ssh into my mac mini and start claude there"

### Or set a key by hand

The easy way: click the UwU face in your menu bar > Configure keys, pick Type, Run or Script for each key ( Choose… starts in `~/.config/uwu/scripts/`, a handy home for your own ), hit Test, then Save. No JSON.

Rather type it yourself? Just like the old computer magazines, here is how you can add your own! That's `~/.config/uwu/actions.json`, one entry per key, left to right:

```json
[
  {"script": "examples/scratch-claude.sh"},
  {"script": "scripts/standup.sh"},
  {"type": "yes"}
]
```

Relative paths start in `~/.config/uwu/`, and `~/...` or absolute paths work too, so your scripts can live anywhere ( the clone's `scripts/` folder is gitignored for exactly that ). 3KC re-reads the file on every press, no restart. Scripts run with 3KC's permissions ( Accessibility included ), so only run scripts you've read. [guide.md](guide.md#make-the-script-macros-yours) has the details.

### The examples

A few ready-made scripts live in [examples/](examples/), and 3KC copies them to `~/.config/uwu/examples/` on first launch. The folder and the terminal or app sit right at the top of each one, change them and you're done:

- `new-claude-session.sh` starts claude code in a new terminal window, iterm2 if you have it, else ghostty, else terminal ( Macro key 1 runs this one out of the box )
- `new-claude-session.applescript` does the same in iterm2, as an AppleScript file
- `scratch-claude.sh` makes a fresh, dated scratch folder and starts claude code in it
- `open-project.sh` opens a folder in your editor, or in finder

## The rest

[guide.md](guide.md) is the manual reference for everything the Setup window does, plus the stuff around it: the menu bar icon, the key table to map by hand in case the share code breaks, wispr flow, ghostty, writing your own script macros, reading the log and uninstalling. I write about stuff like this on [my blog](https://constdecimalserrno.dev/).

## Dear wooting

You made a ridiculously fun little pad, thank you! A tiny wishlist from a Mac person, in case you're reading:

- Let me bind Apple's fn / Globe key. Then the Talk key could just BE fn, and every dictation app would work out of the box.
- Text macros or app launching on macOS. Your macro app is Windows and Linux only, so on a Mac the Macro keys need a whole app just to type `yes`.
- Export a profile to a file. Then the mapping could live right here, next to this README, instead of a share code.

## License

MIT, see [LICENSE](LICENSE). Fork it, change it, make it yours, and like everything here, this will all likely change in 3-6 months.

This is a fan project, not affiliated with or endorsed by Anthropic or wooting ( "Claude" is Anthropic's trademark ), and it works with whatever runs in your terminals, claude code is just what I use.

Cheers!

const ( [@const_errno](https://x.com/const_errno) )
