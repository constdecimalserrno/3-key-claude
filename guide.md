# uwu guide

Everything you need to take an UwU and a Mac from zero to working, top to bottom.

Part 1 maps the UwU and hooks up your dictation app, nothing gets installed on the Mac, and you walk away with a working Talk key and Enter key. Part 2 adds the Helper for the Cycle key and the Action keys. Do them in order and stop wherever you're happy.

## Part 1: the UwU

### The key table

Out of the box the UwU types Z / X / C on top and Esc / Space / Fn below. Here's what it sends instead:

| Key | wootility sends | What it does |
|---|---|---|
| Talk key ( top-left ) | Right Ctrl | push-to-talk for your dictation app, hold to talk, double-tap for hands-free |
| Cycle key ( top-middle ) | F13 | moves keyboard focus to the next Session, needs the Helper ( part 2 ) |
| Enter key ( top-right ) | Return | a plain Return to whatever has focus |
| Action keys ( bottom, left to right ) | F16 / F17 / F18 | one Action each, needs the Helper ( part 2 ) |

Good to know:

- The 3 top keys only fire at about 2.0mm with Rapid Trigger OFF, so resting a finger on them does nothing. No accidental Enter, no dictation cut short.
- It's all ONE profile in the UwU's first onboard slot ( P1 ), stored on the UwU itself, so it works without wootility open and on any Mac you plug it into.
- F14 and F15 are skipped on purpose, macOS may treat them as display brightness.
- The bottom-right button is normally wootility's Fn key, so remapping it gives up the Fn layers. Fair trade.

### Import the share code

1. Open [wootility](https://wooting.io/wootility) and plug in the UwU.
2. Go to My Profiles > Import Profile, paste this share code and click Import: `8ee6080d758ae0da37a7f8b6c9604399d265`
3. The profile now lives in wootility, not on the UwU yet. Drag it into the Onboard profiles section, first slot ( its menu may also offer Move to Onboard ).
4. Open any text editor and press the Enter key, you get a new line. The other keys seem to do nothing yet, that's right, keep going.

There's no one-click import link, GitHub strips the custom link scheme wootility's desktop app uses, so copy-paste it is.

### Or map it by hand

Share code not working ( wootility changes, codes go stale )? Same thing by hand, in wootility, on the UwU's first onboard profile:

1. Open the Remap tab.
2. For every key in the table above, find what it should send in the list on the right ( the "Search for a character" box helps, Right Ctrl shows up as `^ Ctrl`, the second one ) and drag it onto the key. Clicking a key gives you "Press any key to bind" too, but most Mac keyboards have no Right Ctrl or F13 to press, so dragging it is.
3. Open the Actuation Point tab, click Select all keys ( only the 3 top keys are analog, so that's them ) and type 2.00 into the mm box.
4. Open the Rapid Trigger tab and, with those 3 still selected, switch Enable Rapid Trigger off.
5. Click Save to Keyboard, top right. NOTHING reaches the UwU until you do.

### The dictation hotkey

I use wispr flow, but any dictation app that takes Right Ctrl as a hotkey works the same way.

1. Open wispr flow's settings and find the push-to-talk shortcut.
2. ADD the Talk key as an extra shortcut ( press it when wispr flow asks, it shows up as Right Ctrl ). Keep fn, the UwU adds a hotkey, it doesn't replace one.
3. Hold the Talk key and talk, let go and the text lands wherever your cursor is. Double-tap it for hands-free.

wispr flow won't take Right Ctrl on its own? Use Right Option instead, in BOTH places: give the Talk key Right Option in wootility's Remap tab, then add it in wispr flow.

That's the Talk key and the Enter key done, with nothing installed on the Mac. The Cycle key and the Action keys send keys macOS ignores out of the box, so they stay quiet until part 2.

## Part 2: the Helper

The Helper is a tiny app that sits in the background, listens for the Cycle key and the Action keys, and does the thing. It gets built from source on YOUR Mac with Apple's own tools ( no homebrew, no third-party code, no xcode project ), it has no Dock or menu bar icon, it never touches the network, and all of it lives in `helper/`, small enough to read over one coffee. Please do, you're about to give it Accessibility.

The Talk key and the Enter key work without it, so if that's all you want, you're done.

### Install

1. Clone the repo and run the installer from inside it ( never pipe an installer straight from the internet, read it first, this one is short ):

   ```sh
   git clone https://github.com/constdecimalserrno/wooting-uwu-ai.git
   cd wooting-uwu-ai
   ./install.sh
   ```

2. No Command Line Tools yet? The installer asks macOS to install them and stops, so click Install, wait for it, and run `./install.sh` again.
3. macOS might tell you a background item was added, that's Kuro, the Helper. It starts at login from now on.
4. Grant Accessibility, right below.

Updating is `git pull` and `./install.sh` again, it's safe to re-run as often as you like.

### Grant Accessibility

The Helper types for you, and macOS ( rightfully ) wants your yes first.

1. The installer opens System Settings > Privacy & Security > Accessibility for you, and the Helper asks too.
2. Flip the switch next to Kuro.

That's it, no restart needed.

The first time the Cycle key or an Action talks to another app ( like iterm2 ), macOS asks if Kuro may control it. Click Allow.

### Re-grant after EVERY reinstall

The Helper is ad-hoc signed, so every build is a brand new app as far as macOS is concerned, and macOS forgets it ever trusted it. The installer wipes the stale grants for you, so after each `./install.sh` you just flip the Kuro switch under Accessibility again ( and click Allow again on the next Automation prompt ). If a key stops working right after an update, it's this. Every time.

If the installer said it couldn't reset the old grants, select Kuro in the Accessibility list, remove it with the - button, then add it back with + ( it lives in `~/Applications` ).

### Cycle key

Every press of the Cycle key ( wootility sends F13 ) moves keyboard focus to the next Session, so you press it and just start typing there. A Session is one running terminal in iterm2 or ghostty, and every split pane counts as its own Session.

The Cycle goes through iterm2 first, then ghostty, window by window, then tab by tab, then pane by pane, and after the last Session it wraps back to the first. That order is FIXED, it doesn't reshuffle as focus moves, so 5 presses visit 5 different Sessions and your fingers learn the way. Muscle memory.

Good to know:

- Minimized windows and iterm2's hotkey window are skipped, so the Cycle never pops a window you put away ( ghostty is a bit different, see below ).
- In any other app ( say your browser ), the first press takes you back to the terminal app you were in last, and from there it cycles as usual.
- No Sessions open, or no terminal app even running? Then it does nothing. The Helper NEVER launches iterm2 or ghostty just to ask what's open.
- The Cycle key doesn't need Accessibility, only the Automation yes below ( one per terminal app ).

Sessions on other Spaces and in full-screen windows are in the Cycle too, but macOS only takes you over there with this one switched on:

1. Open System Settings > Desktop & Dock.
2. Scroll down to Mission Control.
3. Turn on "When switching to an application, switch to a Space with open windows for the application".

Without it, the Cycle can land you on a Session you can't see.

The first press also asks for one more permission: macOS wants to know if Kuro may control iterm2 ( that's how it reads your Sessions and focuses the next one ). Click Allow, it's a one-time thing ( well, once per reinstall, same deal as Accessibility ). The Helper only waits 2 seconds for a terminal app to answer, so a stuck one can't freeze your keys, which also means the press that brought up the prompt probably did nothing. Just press again after Allow. Clicked Don't Allow by accident, or the log says something about not being authorized to send Apple events? Flip it back on:

1. Open System Settings > Privacy & Security > Automation.
2. Expand Kuro.
3. Turn on the switch next to iterm2 ( or ghostty ).

### ghostty

Got ghostty? Its Sessions join the Cycle right after iterm2's, so one Cycle key walks through both apps and wraps around. Only one of the two running is fine too.

1. You need ghostty 1.3 or newer, that's the first one that speaks AppleScript ( Ghostty > About Ghostty tells you ).
2. The first press with ghostty open asks if Kuro may control ghostty, the same one-time Automation prompt as for iterm2. Click Allow, then press again.
3. ghostty's AppleScript must stay on. It's on by default, so you only need to care if your ghostty config has this line, delete it ( or make it `true` ) and restart ghostty:

   ```ini
   macos-applescript = false
   ```

Good to know: ghostty's quick terminal is never in the Cycle, but a minimized ghostty window IS, because ghostty doesn't tell scripts which windows are minimized, so the Cycle pops it right back up. Sorry. Also, ghostty still calls its AppleScript a preview, so a future ghostty might break this ( like everything here, this will all likely change in 3-6 months ).

### Action keys

The three small bottom keys each do one Action, left to right:

| Action key | wootility sends | Default Action |
|---|---|---|
| left | F16 | opens a new iterm2 window and brings it to the front |
| middle | F17 | types `yes` |
| right | F18 | types `no` |

Typing NEVER presses Return at the end, that's the Enter key's job, so nothing gets sent until you say so. It also ignores any modifier you're holding, so `yes` never shows up as ctrl-y-e-s just because your thumb is still on the Talk key.

### Make the Actions yours

The Actions live in `~/.config/uwu/actions.json`, a list of three entries, one per Action key, left to right. Each entry is either `{"type": "..."}` to type some text, or `{"run": "..."}` to run a shell command ( through `/bin/sh -c`, fire-and-forget ). The Helper re-reads the file on EVERY press, so save, press, done. No reinstall, no re-grant.

Just like the old computer magazines, here is how you can add your own!

```json
[
  {"run": "open https://wooting.io/uwu"},
  {"type": "dear clanker, run the tests before you tell me it works"},
  {"run": "say uwu"}
]
```

Good to know:

- Commands get the tiny PATH that launchd hands out ( `/usr/bin:/bin:/usr/sbin:/sbin` ), so anything you installed yourself needs its full path.
- A `"` inside your text is `\"` and a `\` is `\\`, that's just JSON.
- A missing file, a typo or a missing entry makes that key do nothing and log why, it NEVER takes the Helper down.
- Want the defaults back? From the clone:

  ```sh
  cp helper/actions.json ~/.config/uwu/actions.json
  ```

### Reading the log

When a key does nothing, the Helper says why. Leave this running, press the key and watch:

```sh
/usr/bin/log stream --style compact --predicate 'eventMessage BEGINSWITH "uwu:"'
```

Yes, the full path, zsh has its own built-in `log` that just says "too many arguments". Ctrl-C stops it, and `show --last 1h` instead of `stream` looks back instead of waiting. Commands you run show up in there, typed text never does ( just how many characters ).

Granted Accessibility and typing still does nothing? Kick the Helper:

```sh
pkill -x Kuro; open -a Kuro
```

### Uninstall

```sh
./install.sh uninstall
```

That takes Kuro out of your login items, removes the app and leaves `~/.config/uwu/actions.json` alone, in case you come back. Delete it by hand if you want it gone too.

### Run the tests

The Helper's brain ( `helper/core.swift` ) is ONE pure function: which key fired + a snapshot of the world in, the one thing to do out. `helper/tests.swift` pokes it with fake worlds, no xcode, no XCTest, just swiftc:

```sh
./install.sh test
```

It prints every case and exits non-zero when anything fails, so you, me and the clankers all get the same answer.
