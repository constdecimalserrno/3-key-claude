# uwu guide

Everything you need to take an UwU and a Mac from zero to working, top to bottom.

Part 1 ( mapping the UwU, the Talk key and the Enter key ) is coming soon.

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
3. macOS might tell you a background item was added, that's the Helper. It starts at login from now on and comes back by itself if it ever crashes.
4. Grant Accessibility, right below.

Updating is `git pull` and `./install.sh` again, it's safe to re-run as often as you like.

### Grant Accessibility

The Helper types for you, and macOS ( rightfully ) wants your yes first.

1. The installer opens System Settings > Privacy & Security > Accessibility for you, and the Helper asks too.
2. Flip the switch next to UwU Helper.

That's it, no restart needed.

The first time the Cycle key or an Action talks to another app ( like iterm2 ), macOS asks if UwU Helper may control it. Click Allow.

### Re-grant after EVERY reinstall

The Helper is ad-hoc signed, so every build is a brand new app as far as macOS is concerned, and macOS forgets it ever trusted it. The installer wipes the stale grants for you, so after each `./install.sh` you just flip the UwU Helper switch under Accessibility again ( and click Allow again on the next Automation prompt ). If a key stops working right after an update, it's this. Every time.

If the installer said it couldn't reset the old grants, select UwU Helper in the Accessibility list, remove it with the - button, then add it back with + ( it lives in `~/Applications` ).

### Cycle key

Every press of the Cycle key ( wootility sends F13 ) moves keyboard focus to the next Session, so you press it and just start typing there. A Session is one running terminal in iterm2, and every split pane counts as its own Session.

The Cycle goes window by window, then tab by tab, then pane by pane, and after the last Session it wraps back to the first. That order is FIXED, it doesn't reshuffle as focus moves, so 5 presses visit 5 different Sessions and your fingers learn the way. Muscle memory.

Good to know:

- Minimized windows and iterm2's hotkey window are skipped, so the Cycle never pops a window you put away.
- In any other app ( say your browser ), the first press takes you back to the terminal app you were in last, and from there it cycles as usual.
- No Sessions open, or iterm2 isn't even running? Then it does nothing. The Helper NEVER launches iterm2 just to ask what's open.
- The Cycle key doesn't need Accessibility, only the one Automation yes below.

Sessions on other Spaces and in full-screen windows are in the Cycle too, but macOS only takes you over there with this one switched on:

1. Open System Settings > Desktop & Dock.
2. Scroll down to Mission Control.
3. Turn on "When switching to an application, switch to a Space with open windows for the application".

Without it, the Cycle can land you on a Session you can't see.

The first press also asks for one more permission: macOS wants to know if UwU Helper may control iterm2 ( that's how it reads your Sessions and focuses the next one ). Click Allow, it's a one-time thing ( well, once per reinstall, same deal as Accessibility ). Clicked Don't Allow by accident, or the log says something about not being authorized to send Apple events? Flip it back on:

1. Open System Settings > Privacy & Security > Automation.
2. Expand UwU Helper.
3. Turn on the switch next to iterm2.

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
log stream --style compact --predicate 'eventMessage BEGINSWITH "uwu:"'
```

Ctrl-C stops it, and `log show --last 1h` instead of `log stream` looks back instead of waiting. Commands you run show up in there, typed text never does ( just how many characters ).

Granted Accessibility and typing still does nothing? Kick the Helper:

```sh
launchctl kickstart -k gui/$(id -u)/dev.constdecimalserrno.uwu
```

### Uninstall

```sh
./install.sh uninstall
```

That removes the app and its LaunchAgent and leaves `~/.config/uwu/actions.json` alone, in case you come back. Delete it by hand if you want it gone too.

### Run the tests

The Helper's brain ( `helper/core.swift` ) is ONE pure function: which key fired + a snapshot of the world in, the one thing to do out. `helper/tests.swift` pokes it with fake worlds, no xcode, no XCTest, just swiftc:

```sh
./install.sh test
```

It prints every case and exits non-zero when anything fails, so you, me and the clankers all get the same answer.
