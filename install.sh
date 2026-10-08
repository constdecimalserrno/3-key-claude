#!/bin/sh
# Builds and installs 3-key Claude, the Helper app. Safe to re-run, updating is git pull + this again.
#
#   ./install.sh                 install or update, into ~/Applications
#   ./install.sh uninstall       remove it ( from ~/Applications AND /Applications ), keep your Actions file
#   ./install.sh build           only build, installs NOTHING
#   ./install.sh dmg             build 3KeyClaude.dmg to hand around, installs NOTHING
#   ./install.sh test            run the Helper core tests
#   ./install.sh release <tag>   maintainer only: build the .dmg and publish it as a GitHub release
set -eu
cd "$(dirname "$0")"

ID=dev.constdecimalserrno.uwu
NAME="3-key Claude"
SHORT=3KC # for the chatter below
EXE=3KeyClaude # no spaces, so `pkill -x 3KeyClaude` just works
# outside the clone, because iCloud ( say a clone in ~/Documents ) tags .app folders and codesign refuses those
BUILD="${TMPDIR:-/tmp}/uwu-build"
BUILT="$BUILD/$NAME.app"
DMG="$BUILD/$EXE.dmg"
APP="$HOME/Applications/$NAME.app"
DMG_APP="/Applications/$NAME.app" # where the .dmg has you drag it
ACTIONS="$HOME/.config/uwu/actions.json"

say() { printf 'uwu: %s\n' "$*"; }

need_tools() {
    if ! xcode-select -p >/dev/null 2>&1; then
        say "you need Apple's Command Line Tools first, I just asked macOS to install them"
        say "click Install, wait for it to finish, then run me again"
        xcode-select --install >/dev/null 2>&1 || true
        exit 1
    fi
}

# $1: the chips to build for, THIS Mac's by default ( the .dmg asks for both )
build() {
    need_tools
    say "building $SHORT ( takes a few seconds )"
    rm -rf "$BUILT" "$BUILD/AppIcon.iconset" "$BUILD/chips"
    mkdir -p "$BUILT/Contents/MacOS" "$BUILT/Contents/Resources" "$BUILD/chips"
    cp helper/Info.plist "$BUILT/Contents/"
    # the default Actions and the example scripts, the app copies them out on first launch
    cp helper/actions.json "$BUILT/Contents/Resources/"
    cp -R examples "$BUILT/Contents/Resources/"
    # the app icon, drawn fresh from vectors on every build ( Info.plist points CFBundleIconFile at AppIcon )
    swift helper/icon.swift "$BUILD" >/dev/null
    iconutil -c icns "$BUILD/AppIcon.iconset" -o "$BUILT/Contents/Resources/AppIcon.icns"
    # one compile per chip, then lipo glues them into one app that runs on both
    for chip in ${1:-$(uname -m)}; do
        swiftc -O -swift-version 5 -target "$chip-apple-macos13.0" \
            helper/core.swift helper/setup.swift helper/main.swift -o "$BUILD/chips/$chip"
    done
    lipo -create "$BUILD/chips/"* -output "$BUILT/Contents/MacOS/$EXE"
    xattr -cr "$BUILT" # same story for attributes copied over from the clone
    # ponytail: ad-hoc means a brand new identity on EVERY build, so macOS forgets the Accessibility grant each time
    codesign --force --sign - "$BUILT"
}

# the .dmg: the app, a shortcut to /Applications to drag it onto, and a read-me for the one-time Open Anyway
# universal, so Apple silicon AND Intel Macs can use the same download
dmg() {
    build "arm64 x86_64"
    rm -rf "$BUILD/dmg" "$DMG"
    mkdir -p "$BUILD/dmg"
    ditto "$BUILT" "$BUILD/dmg/$NAME.app"
    ln -s /Applications "$BUILD/dmg/Applications"
    cat > "$BUILD/dmg/read me first.txt" <<'EOF'
3-key claude
talk. hop. enter.

Run your ENTIRE agentic workflow from the 3 top keys of a wooting UwU: the Talk key tells a clanker what to do, the Cycle key hops to the next one, the Enter key approves. The 3 small keys below are bonus Actions.

1. Drag 3-key Claude onto the Applications folder right next to it.
2. Open it from your Applications folder ( NOT from in here, it just tells you to drag it first ).
3. macOS blocks it the first time, because it isn't notarized ( that needs a paid Apple developer account ). Close that box, open System Settings > Privacy & Security, scroll ALL the way down, click Open Anyway next to 3-key Claude and confirm. Once, never again.
4. The Setup window walks you through everything else, the UwU included.

The source, the guide and the whole story: https://github.com/constdecimalserrno/3-key-claude

Cheers!
const
EOF
    hdiutil create -quiet -volname "$NAME" -srcfolder "$BUILD/dmg" -format UDZO "$DMG"
}

# takes every copy out of the login items and quits it, a fresh one adds itself back on launch
stop() {
    for app in "$APP" "$DMG_APP"; do
        if [ -x "$app/Contents/MacOS/$EXE" ]; then "$app/Contents/MacOS/$EXE" --uninstall >/dev/null 2>&1 || true; fi
    done
    pkill -x "$EXE" || true
}

# the one install from before the rename: a LaunchAgent running ~/Applications/UwU Helper.app
migrate() {
    OLD_AGENT="$HOME/Library/LaunchAgents/$ID.plist"
    OLD_APP="$HOME/Applications/UwU Helper.app"
    if [ -e "$OLD_AGENT" ] || [ -e "$OLD_APP" ]; then
        say "moving you over from UwU Helper to $SHORT"
        if [ -e "$OLD_AGENT" ]; then launchctl bootout "gui/$(id -u)" "$OLD_AGENT" >/dev/null 2>&1 || true; fi
        rm -f "$OLD_AGENT"
        rm -rf "$OLD_APP"
    fi
}

# the old grants belong to the old build, they are stale now
reset_grants() {
    tccutil reset Accessibility "$ID" >/dev/null 2>&1 && tccutil reset AppleEvents "$ID" >/dev/null 2>&1
}

case "${1:-install}" in
install)
    build
    stop
    migrate
    say "installing to ~/Applications/$NAME.app"
    mkdir -p "$HOME/Applications"
    rm -rf "$APP"
    ditto "$BUILT" "$APP"
    reset_grants || say "couldn't reset the old permission grants ( fine on a first install ), if $NAME is already under Accessibility, remove it with the - button first"
    [ -e "$ACTIONS" ] || say "the app puts the default Actions file and the example scripts in ~/.config/uwu/, make them yours!"
    open "$APP" # the first launch adds it to the login items
    say "$SHORT is running, and it starts at login from now on"
    if [ -e "$DMG_APP" ]; then say "heads up, there's another copy in /Applications ( from the .dmg? ), drag one of the two to the Trash"; fi
    if [ "$(defaults read "$ID" setupDone 2>/dev/null || true)" = 1 ]; then
        say "LAST step: flip the switch next to $NAME in the Accessibility list I just opened ( again after EVERY reinstall )"
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    else
        say "its Setup window walks you through the rest, the UwU included"
    fi
    ;;
uninstall)
    stop
    migrate
    rm -rf "$APP"
    if [ -e "$DMG_APP" ]; then rm -rf "$DMG_APP" || say "couldn't remove $DMG_APP, drag it to the Trash yourself"; fi
    reset_grants || true
    defaults delete "$ID" >/dev/null 2>&1 || true # so a comeback gets the Setup window again
    say "$SHORT is gone, your Actions file and the examples are still in ~/.config/uwu/ in case you come back"
    ;;
build)
    build
    say "built into $BUILD, NOTHING got installed"
    ;;
dmg)
    dmg
    say "made $DMG, NOTHING got installed"
    ;;
release)
    # maintainer only: gh is MY tool for publishing, nobody needs it to build, install or run the Helper
    TAG="${2:-}"
    [ -n "$TAG" ] || { say "usage: ./install.sh release <tag>"; exit 1; }
    command -v gh >/dev/null 2>&1 || { say "release needs gh, the GitHub CLI ( maintainer only, nobody else needs it )"; exit 1; }
    dmg
    # tags the commit you built from, so push it first
    gh release create "$TAG" "$DMG" --target "$(git rev-parse HEAD)" --title "$NAME $TAG" --notes "talk. hop. enter.

Download 3KeyClaude.dmg, drag the app into Applications and open it from there. macOS blocks it the first time because it isn't notarized, so go to System Settings > Privacy & Security, scroll ALL the way down, click Open Anyway and confirm. Once, never again. The Setup window does the rest.

Runs on Apple silicon and Intel, macOS 13 or newer. Cheers!"
    ;;
test)
    need_tools
    mkdir -p "$BUILD"
    swiftc -swift-version 5 helper/core.swift helper/tests.swift -o "$BUILD/tests"
    exec "$BUILD/tests" helper/actions.json
    ;;
*)
    say "usage: ./install.sh [uninstall | build | dmg | test | release <tag>]"
    exit 1
    ;;
esac
