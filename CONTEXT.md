# uwu

One Wooting UwU macropad wired into a Mac for voice dictation, hopping between terminals and one-key actions.

## Language

### Keys

**Talk key**:
The UwU's top-left key, shared with a dictation app such as Wispr Flow ( hold to talk, double-tap for hands-free ).
_Avoid_: Wispr key, voice key, dictation key, fn key

**Cycle key**:
The UwU's top-middle key; each press is one step through the Cycle.
_Avoid_: switch key, terminal key

**Enter key**:
The UwU's top-right key; a plain Return to whatever has focus.
_Avoid_: confirm key, approve key, return key

**Action key**:
One of the UwU's three small bottom keys, each bound to exactly one Action.
_Avoid_: macro key, snippet key, bottom button

**Three-key workflow**:
The agentic loop run from the UwU's 3 top keys: Talk ( tell a clanker what to do ), Cycle ( hop to the next one ), Enter ( approve ).
_Avoid_: three-button workflow, three-key flow, 3-button loop

### Cycling

**Session**:
One running terminal in iTerm2 or Ghostty; every split pane is its own Session.
_Avoid_: terminal, shell, tab, pane, Stop

**Cycle**:
The fixed, wrap-around order of every Session ( iTerm2 first, then Ghostty ) that the Cycle key steps through. Sessions in minimized windows or drop-down windows ( iTerm2's hotkey window, Ghostty's quick terminal ) are left out.
_Avoid_: switcher, rotation, MRU

### Helper

**Helper**:
The optional background app on the Mac that powers the Cycle key and Action keys; the Talk key and Enter key work without it. The app itself is called 3-key Claude ( 3KC for short ).
_Avoid_: daemon, agent, service, UwU Helper, Kuro, Three-Button Workflow, Three-Key Workflow

**Setup window**:
The Helper's one-time window that walks you through the whole setup, one step per page, with a live check for every key; it opens on first launch and whenever the app is opened while already running.
_Avoid_: onboarding, wizard, welcome screen

### Actions

**Action**:
The one thing an Action key does: type a piece of text, run a shell command, or run a script file ( any bash or AppleScript file, like the ready-made examples ).
_Avoid_: macro, snippet, shortcut
