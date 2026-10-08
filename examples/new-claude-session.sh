#!/bin/sh
# Starts claude code in a new terminal window, in the folder below. Macro key 1 runs this one out of the box.
# iterm2 if you have it, else ghostty, else terminal ( the one every Mac has ).

# the folder claude starts in
FOLDER="$HOME"
# "iterm2", "ghostty" or "terminal", or "" for the first one you have, in that order
TERMINAL=""

# a folder handed to me wins ( scratch-claude.sh does that )
if [ -n "${1:-}" ]; then FOLDER="$1"; fi

# ponytail: only looks in the two Applications folders, an app anywhere else needs TERMINAL set by hand
has() { [ -d "/Applications/$1.app" ] || [ -d "$HOME/Applications/$1.app" ]; }
if [ -z "$TERMINAL" ]; then
    if has iTerm; then TERMINAL=iterm2; elif has Ghostty; then TERMINAL=ghostty; else TERMINAL=terminal; fi
fi

# the folder goes in as an argument, NOT pasted into the AppleScript, so spaces and quotes in it are fine
case "$TERMINAL" in
iterm2) osascript - "$FOLDER" <<'EOF'
on run {dir}
    set cmd to "cd " & quoted form of dir & " && claude"
    tell application id "com.googlecode.iterm2"
        tell current session of (create window with default profile) to write text cmd
        activate
    end tell
end run
EOF
    ;;
ghostty) osascript - "$FOLDER" <<'EOF'
on run {dir}
    tell application id "com.mitchellh.ghostty"
        set cfg to new surface configuration
        set initial working directory of cfg to dir
        set initial input of cfg to "claude" & linefeed
        new window with configuration cfg
        activate
    end tell
end run
EOF
    ;;
*) osascript - "$FOLDER" <<'EOF'
on run {dir}
    tell application id "com.apple.Terminal"
        do script "cd " & quoted form of dir & " && claude"
        activate
    end tell
end run
EOF
    ;;
esac
