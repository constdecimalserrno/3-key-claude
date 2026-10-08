#!/bin/sh
# Opens a folder in an app, say your project in your editor, or just in finder.

# the folder to open
FOLDER="$HOME"
# the app to open it in, as it's called in your Applications folder ( say "Zed" or "Visual Studio Code" ), "" is finder
APP=""

if [ -n "$APP" ]; then open -a "$APP" "$FOLDER"; else open "$FOLDER"; fi
