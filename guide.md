# 3-key Claude guide

Everything you need to take an UwU and a Mac from zero to the three-key workflow: talk. hop. enter.

## The fast path

1. Download [3KeyClaude.dmg](https://github.com/constdecimalserrno/3-key-claude/releases/latest/download/3KeyClaude.dmg) ( Apple silicon or Intel, macOS 13 or newer ), open it and drag 3-key Claude onto the Applications folder next to it.
2. Open 3-key Claude from your Applications folder. macOS blocks it the first time, because it isn't notarized, so close that box, open System Settings > Privacy & Security, scroll ALL the way down, click Open Anyway next to 3-key Claude and confirm. Once, never again.
3. Follow the Setup window. One page per step, with a live check for every key:
   1. The UwU: copy the share code, open wootility, import it, press the Enter key.
   2. Accessibility: flip the switch, the check goes green by itself.
   3. The Talk key: add it to wispr flow, press it.
   4. Your terminals: click Ask so macOS asks about iterm2 and ghostty NOW, check the Spaces setting, press the Cycle key.
   5. The Action keys: press all three.

Good to know:

- While the Setup window is open, the Cycle key and the Action keys ONLY tick their boxes. Close it and they're real.
- Closing it on the last page marks setup done. Close it earlier and it comes back at your next login.
- Want it back? Open 3-key Claude again ( Finder, Launchpad, Spotlight ), it's running anyway.
- Opened it straight from the `.dmg`? It tells you to drag it into Applications first and quits, nothing gets set up from in there.

Everything below is the manual reference: what the Setup window does, step by step, for when you'd rather do it by hand, something breaks, or you're just curious. Part 1 maps the UwU and hooks up your dictation app with nothing installed on the Mac, part 2 is 3KC itself.

## Part 1: the UwU

### The key table

Out of the box the UwU types Z / X / C on top and Esc / Space / Fn below. Here's what it sends instead:

| Key | wootility sends | What it does |
|---|---|---|
| Talk key ( top-left ) | Right Ctrl | push-to-talk for your dictation app, hold to talk, double-tap for hands-free |
| Cycle key ( top-middle ) | F13 | moves keyboard focus to the next Session, needs 3KC ( part 2 ) |
| Enter key ( top-right ) | Return | a plain Return to whatever has focus |
| Action keys ( bottom, left to right ) | F16 / F17 / F18 | one Action each, needs 3KC ( part 2 ) |

Good to know:

- The 3 top keys only fire at about 2.0mm with Rapid Trigger OFF, so resting a finger on them does nothing. No accidental Enter, no dictation cut short.
- It's all ONE profile in the UwU's first onboard slot ( P1 ), stored on the UwU itself, so it works without wootility open and on any Mac you plug it into.
- F14 and F15 are skipped on purpose, macOS may treat them as display brightness.
- The bottom-right button is normally wootility's Fn key, so remapping it gives up the Fn layers. Fair trade.

### Import the share code

1. Plug in the UwU and open [wootility](https://wootility.io) in chrome, edge or arc. It's a web app, and safari can't talk to the UwU.
2. Go to My Profiles > Import Profile, paste this share code and click Import: `8ee6080d758ae0da37a7f8b6c9604399d265`
3. The profile now lives in wootility, under your inactive profiles, not on the UwU yet. Drag it into the Onboard profiles section, first slot.
4. Open any text editor and press the Enter key, you get a new line. The other keys seem to do nothing yet, that's right, keep going.

There's no one-click import link, GitHub strips the custom link scheme wootility uses, so copy-paste it is.

### Or map it by hand

Share code not working ( wootility changes, codes go stale )? Same thing by hand, in wootility, on the UwU's first onboard profile:

1. Open the Remap tab.
2. For every key in the table above, find what it should send in the list on the right ( the "Search for a character" box helps, Right Ctrl shows up as `^ Ctrl`, the second one ) and drag it onto the key. Clicking a key gives you "Press any key to bind" too, but most Mac keyboards have no Right Ctrl or F13 to press, so dragging it is.
3. Open the Actuation Point tab, click Select all keys ( only the 3 top keys are analog, so that's them ) and type 2.00 into the mm box.
4. Open the Rapid Trigger tab and, with those 3 still selected, switch Enable Rapid Trigger off.
5. Click Save to Keyboard, top right. NOTHING reaches the UwU until you do.

### The dictation hotkey

I use wispr flow, but any dictation app that takes Right Ctrl as a hotkey works the same way.

1. Click wispr flow's menu bar icon, then Settings > General > Shortcuts > Change.
2. In the Push to talk row, click + ( "Add another" ), press the Talk key ( it shows up as Right Ctrl ) and click Done. Keep fn, the UwU adds a hotkey, it doesn't replace one.
3. Hold the Talk key and talk, let go and the text lands wherever your cursor is. Double-tap it for hands-free.

wispr flow won't take Right Ctrl on its own? Use Right Option instead, in BOTH places: give the Talk key Right Option in wootility's Remap tab, then add it in wispr flow.

The Talk key does nothing in iterm2? wispr flow's shortcuts are blocked while iterm2's Secure Keyboard Entry is on, switch it off in the iTerm2 menu.

That's the Talk key and the Enter key done, with nothing installed on the Mac. The Cycle key and the Action keys send keys macOS ignores out of the box, so they stay quiet until part 2.

## Part 2: 3-key Claude, the Helper

3-key Claude ( 3KC for short ) is a tiny app that sits in the background, listens for the Cycle key and the Action keys, and does the thing. It uses only Apple's own frameworks ( no homebrew, no third-party code, no xcode project ), it has no Dock or menu bar icon, it never touches the network, and all of it lives in `helper/`, small enough to read over one coffee. Please do, you're about to give it Accessibility.

The Talk key and the Enter key work without it, so if that's all you want, you're done.

### Install

Two ways, both end in the same Setup window.

The `.dmg` ( Apple silicon and Intel ): the fast path at the top. It's ad-hoc signed, NOT notarized ( that needs a paid Apple developer account, see [ADR-0002](docs/adr/0002-ad-hoc-signed-dmg.md) ), so the first open needs that one-time Open Anyway in System Settings > Privacy & Security. Updating is downloading the new `.dmg` and dragging it over the old one.

From source:

1. Clone the repo and run the installer from inside it ( never pipe an installer straight from the internet, read it first, this one is short ):

   ```sh
   git clone https://github.com/constdecimalserrno/3-key-claude.git
   cd 3-key-claude
   ./install.sh
   ```

2. No Command Line Tools yet? The installer asks macOS to install them and stops, so click Install, wait for it, and run `./install.sh` again.
3. It builds 3KC into `~/Applications` and opens it. Updating is `git pull` and `./install.sh` again, safe to re-run as often as you like.

Either way, macOS might tell you a background item was added, that's 3KC. It starts at login from now on.

### Grant Accessibility

3KC types for you, and macOS ( rightfully ) wants your yes first. The Setup window's Accessibility step does this with you and goes green the moment it works. By hand:

1. Open System Settings > Privacy & Security > Accessibility.
2. Flip the switch next to 3-key Claude. Not in the list? Add it with + from your Applications folder.

That's it, no restart needed.

### Re-grant after EVERY update

3KC is ad-hoc signed, so every build ( every new `.dmg`, every `./install.sh` ) is a brand new app as far as macOS is concerned, and macOS forgets it ever trusted it. If a key stops working right after an update, it's this. Every time.

- From source: the installer wipes the stale grants for you, so you just flip the 3-key Claude switch under Accessibility again ( and click Allow again on the next Automation prompt ).
- From the `.dmg`, or the installer said it couldn't reset the old grants: the old switch may still LOOK on. Select 3-key Claude in the Accessibility list, remove it with the - button, then add it back with +.

### Cycle key

Every press of the Cycle key ( wootility sends F13 ) moves keyboard focus to the next Session, so you press it and just start typing there. A Session is one running terminal in iterm2 or ghostty, and every split pane counts as its own Session.

The Cycle goes through iterm2 first, then ghostty, window by window, then tab by tab, then pane by pane, and after the last Session it wraps back to the first. That order is FIXED, it doesn't reshuffle as focus moves, so 5 presses visit 5 different Sessions and your fingers learn the way. Muscle memory.

Good to know:

- Minimized windows and iterm2's hotkey window are skipped, so the Cycle never pops a window you put away ( ghostty is a bit different, see below ).
- In any other app ( say your browser ), the first press takes you back to the terminal app you were in last, and from there it cycles as usual.
- No Sessions open, or no terminal app even running? Then it does nothing. 3KC NEVER launches iterm2 or ghostty just to ask what's open.
- The Cycle key doesn't need Accessibility, only the Automation yes below ( one per terminal app ).

Sessions on other Spaces and in full-screen windows are in the Cycle too, but macOS only takes you over there with this one switched on ( the Setup window shows whether it is ):

1. Open System Settings > Desktop & Dock.
2. Scroll down to Mission Control.
3. Turn on "When switching to an application, switch to a Space with open windows for the application".

Without it, the Cycle can land you on a Session you can't see.

macOS also wants to know, once per terminal app, if 3KC may control it ( that's how it reads your Sessions and focuses the next one ). The Setup window's Ask button brings those prompts up on purpose and gives you a whole minute to click Allow. Skipped that? Then the first Cycle press asks instead, and since 3KC only waits 2 seconds for a terminal app to answer ( so a stuck one can't freeze your keys ), that press probably does nothing. Just press again after Allow. Clicked Don't Allow by accident, or the log says something about not being authorized to send Apple events? Flip it back on:

1. Open System Settings > Privacy & Security > Automation.
2. Expand 3-key Claude.
3. Turn on the switch next to iterm2 ( or ghostty ).

### ghostty

Got ghostty? Its Sessions join the Cycle right after iterm2's, so one Cycle key walks through both apps and wraps around. Only one of the two running is fine too.

1. You need ghostty 1.3 or newer, that's the first one that speaks AppleScript ( Ghostty > About Ghostty tells you ).
2. macOS asks if 3KC may control ghostty, the same one-time Automation prompt as for iterm2. Click Allow ( then press again, if it was a Cycle press that asked ).
3. ghostty's AppleScript must stay on. It's on by default, so you only need to care if your ghostty config has this line, delete it ( or make it `true` ) and restart ghostty:

   ```ini
   macos-applescript = false
   ```

Good to know: ghostty's quick terminal is never in the Cycle, but a minimized ghostty window IS, because ghostty doesn't tell scripts which windows are minimized, so the Cycle pops it right back up. Sorry. Also, ghostty still calls its AppleScript a preview, so a future ghostty might break this ( like everything here, this will all likely change in 3-6 months ).

### Action keys

The three small bottom keys each do one Action, left to right:

| Action key | wootility sends | Default Action |
|---|---|---|
| left | F16 | starts claude code in your home folder, in a new iterm2, ghostty or terminal window |
| middle | F17 | types `yes` |
| right | F18 | types `no` |

Typing NEVER presses Return at the end, that's the Enter key's job, so nothing gets sent until you say so. It also ignores any modifier you're holding, so `yes` never shows up as ctrl-y-e-s just because your thumb is still on the Talk key.

### Make the Actions yours

The Actions live in `~/.config/uwu/actions.json` ( 3KC puts the defaults there on first launch, and the Setup window has an Open Actions file button ), a list of three entries, one per Action key, left to right. Each entry is one of three kinds:

- `{"type": "..."}` types some text.
- `{"run": "..."}` runs a shell command, through `/bin/sh -c`.
- `{"script": "..."}` runs ANY bash or AppleScript file. The path can be absolute, start with `~/`, or be relative to `~/.config/uwu/`. `.applescript` and `.scpt` files run with `osascript`, a file you made executable runs as is ( give it a `#!` line ), anything else runs with `/bin/sh`.

`run` and `script` are fire-and-forget, 3KC starts them and moves on. It re-reads the file on EVERY press, so save, press, done. No reinstall, no re-grant.

### The example scripts

3KC copies these from the repo's `examples/` to `~/.config/uwu/examples/` on first launch, and from then on they're yours. Each one has what you'd want to change as a variable at the top:

| Script | What it does | Change at the top |
|---|---|---|
| `new-claude-session.sh` | starts claude code in a new terminal window, iterm2 if you have it, else ghostty, else terminal. Action key 1 runs it out of the box | `FOLDER`, `TERMINAL` |
| `new-claude-session.applescript` | the same, as an AppleScript file, iterm2 only ( AppleScript won't even start when it names an app you don't have, so the `.sh` does the picking ) | `theFolder` |
| `scratch-claude.sh` | makes a fresh, dated folder like `~/scratch/2026-10-07-153012` and starts claude code in it, through `new-claude-session.sh` | `SCRATCH` |
| `open-project.sh` | opens a folder in an app, say your project in your editor, finder by default | `FOLDER`, `APP` |

The first time a script talks to iterm2, ghostty or terminal, macOS asks if 3KC may control it, click Allow ( the same one-time Automation prompt as for the Cycle key ). Updates NEVER overwrite your copies, so for fresh ones, delete `~/.config/uwu/examples/` and restart 3KC with `pkill -x 3KeyClaude; open -a "3-key Claude"`, or copy them over from the clone.

Just like the old computer magazines, here is how you can add your own! Put a script in the clone's `scripts/` folder ( git ignores everything in there ) or anywhere else you like, say `scripts/standup.sh`:

```sh
#!/bin/sh
# my morning: the notes, the issues, and a clanker ready to go in the repo
open -a Notes
open https://github.com/constdecimalserrno/3-key-claude/issues
exec /bin/sh ~/.config/uwu/examples/new-claude-session.sh ~/code/3-key-claude
```

Then point an Action key at it in `~/.config/uwu/actions.json`, with the path to wherever your clone lives:

```json
[
  {"script": "~/code/3-key-claude/scripts/standup.sh"},
  {"type": "dear clanker, run the tests before you tell me it works"},
  {"run": "say uwu"}
]
```

Scripts run with 3KC's permissions, Accessibility included, so only run scripts you've read.

Good to know:

- Commands and scripts get the tiny PATH that launchd hands out ( `/usr/bin:/bin:/usr/sbin:/sbin` ), so anything you installed yourself needs its full path. The claude examples are fine, `claude` runs inside your terminal's own shell, with your PATH.
- A `"` inside your text is `\"` and a `\` is `\\`, that's just JSON. Editing in TextEdit? Turn off Edit > Substitutions > Smart Quotes first, curly quotes break JSON.
- A missing file, a typo, a missing entry or a script that isn't there makes that key do nothing and log why, it NEVER takes 3KC down.
- Want the defaults back? From the clone:

  ```sh
  cp helper/actions.json ~/.config/uwu/actions.json
  ```

### Reading the log

When a key does nothing, 3KC says why. Leave this running, press the key and watch:

```sh
/usr/bin/log stream --style compact --predicate 'eventMessage BEGINSWITH "uwu:"'
```

Yes, the full path, zsh has its own built-in `log` that just says "too many arguments". Ctrl-C stops it, and `show --last 1h` instead of `stream` looks back instead of waiting. Commands and scripts you run show up in there, typed text never does ( just how many characters ).

Granted Accessibility and typing still does nothing? Kick it:

```sh
pkill -x 3KeyClaude; open -a "3-key Claude"
```

### Uninstall

Got the clone? One command, for a `.dmg` install in `/Applications` and a source install in `~/Applications` alike:

```sh
./install.sh uninstall
```

That takes 3KC out of your login items, quits it, removes the app, forgets its permissions and settings, and leaves `~/.config/uwu/` ( your Actions file and the examples ) alone, in case you come back. Delete that by hand if you want it gone too.

Installed from the `.dmg` and no clone around? Same thing by hand:

```sh
"/Applications/3-key Claude.app/Contents/MacOS/3KeyClaude" --uninstall
pkill -x 3KeyClaude
rm -rf "/Applications/3-key Claude.app"
tccutil reset All dev.constdecimalserrno.uwu
defaults delete dev.constdecimalserrno.uwu
```

The first line takes it out of your login items, then it quits, goes, and forgets its permissions and its settings. Your Actions file and the examples stay.

### Run the tests

3KC's brain ( `helper/core.swift` ) is ONE pure function: which key fired + a snapshot of the world in, the one thing to do out. `helper/tests.swift` pokes it with fake worlds, no xcode, no XCTest, just swiftc:

```sh
./install.sh test
```

It prints every case and exits non-zero when anything fails, so you, me and the clankers all get the same answer.
