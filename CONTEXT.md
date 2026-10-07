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

### Cycling

**Session**:
One running terminal in iTerm2 or Ghostty; every split pane is its own Session.
_Avoid_: terminal, shell, tab, pane, Stop

**Cycle**:
The fixed, wrap-around order of every Session ( iTerm2 first, then Ghostty ) that the Cycle key steps through. Sessions in minimized windows or drop-down windows ( iTerm2's hotkey window, Ghostty's quick terminal ) are left out.
_Avoid_: switcher, rotation, MRU

### Helper

**Helper**:
The optional background app on the Mac that powers the Cycle key and Action keys; the Talk key and Enter key work without it.
_Avoid_: daemon, agent, service

### Actions

**Action**:
The one thing an Action key does: type a piece of text, or run something ( like opening a terminal ).
_Avoid_: macro, snippet, script, shortcut
