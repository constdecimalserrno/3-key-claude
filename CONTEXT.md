# uwu

One Wooting UwU macropad wired into a Mac for voice dictation, hopping between terminals and one-key script macros.

## Language

### Keys

**Talk key**:
The UwU's top-left key, shared with a dictation app such as Wispr Flow ( hold to talk, double-tap for hands-free ).
_Avoid_: Wispr key, voice key, dictation key, fn key

**Hop key**:
The UwU's top-middle key; each press hops one step through the Cycle.
_Avoid_: Cycle key, switch key, terminal key

**Confirm key**:
The UwU's top-right key; a plain Return to whatever has focus.
_Avoid_: Enter key, approve key, return key

**Macro key**:
One of the UwU's three small bottom keys, each running exactly one Script macro.
_Avoid_: Action key, snippet key, bottom button

**Three-key workflow**:
The agentic loop run from the UwU's 3 top keys, "talk. hop. confirm.": Talk ( tell an agent what to do ), Hop ( to the next one ), Confirm ( approve ).
_Avoid_: three-button workflow, three-key flow, 3-button loop, talk. hop. enter.

### Cycling

**Session**:
One running terminal in iTerm2 or Ghostty; every split pane is its own Session.
_Avoid_: terminal, shell, tab, pane, Stop

**Cycle**:
The fixed, wrap-around order of every Session ( iTerm2 first, then Ghostty ) that the Hop key steps through. Sessions in minimized windows or drop-down windows ( iTerm2's hotkey window, Ghostty's quick terminal ) are left out.
_Avoid_: switcher, rotation, MRU

### Helper

**Helper**:
The optional background app on the Mac that powers the Hop key and Macro keys; the Talk key and Confirm key work without it. The app itself is called 3-key Claude ( 3KC for short ).
_Avoid_: daemon, agent, service, UwU Helper, Kuro, Three-Button Workflow, Three-Key Workflow

**Setup window**:
The Helper's one-time window that walks you through the whole setup, one step per page, with a live check for every key; it opens on first launch until you finish it, and again from the menu bar icon.
_Avoid_: onboarding, wizard, welcome screen

**3KC window**:
The Helper's window behind its menu bar icon, for setting the Macro keys without editing a file by hand; it also opens when the app is opened while already running, once setup is done.
_Avoid_: settings, preferences, config window

### Script macros

**Script macro**:
The one thing a Macro key does: type a piece of text, run a shell command, or run any bash or AppleScript file ( like the ready-made examples ).
_Avoid_: Action, snippet, shortcut
