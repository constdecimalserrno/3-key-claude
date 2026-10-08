#!/bin/sh
# Builds and installs Kuro, the Helper app. Safe to re-run, updating is git pull + this again.
#
#   ./install.sh             install or update
#   ./install.sh uninstall   remove Kuro, keep your Actions file
#   ./install.sh build       only build, installs NOTHING
#   ./install.sh dmg         build Kuro.dmg to hand around, installs NOTHING
#   ./install.sh test        run the Helper core tests
set -eu
cd "$(dirname "$0")"

ID=dev.constdecimalserrno.uwu
NAME=Kuro
# outside the clone, because iCloud ( say a clone in ~/Documents ) tags .app folders and codesign refuses those
BUILD="${TMPDIR:-/tmp}/uwu-build"
BUILT="$BUILD/$NAME.app"
APP="$HOME/Applications/$NAME.app"
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

build() {
    need_tools
    say "building Kuro ( takes a few seconds )"
    rm -rf "$BUILT"
    mkdir -p "$BUILT/Contents/MacOS" "$BUILT/Contents/Resources"
    cp helper/Info.plist "$BUILT/Contents/"
    cp helper/actions.json "$BUILT/Contents/Resources/" # the default Actions, Kuro copies them out on first launch
    # ICON: the icon step slots in RIGHT here, helper/icon.swift draws AppIcon.icns into Contents/Resources
    # ( Info.plist already points CFBundleIconFile at AppIcon )
    swiftc -O -swift-version 5 -target "$(uname -m)-apple-macos13.0" \
        helper/core.swift helper/main.swift -o "$BUILT/Contents/MacOS/$NAME"
    xattr -cr "$BUILT" # same story for attributes copied over from the clone
    # ponytail: ad-hoc means a brand new identity on EVERY build, so macOS forgets the Accessibility grant each time
    codesign --force --sign - "$BUILT"
}

# takes Kuro out of the login items and quits it, a fresh one adds itself back on launch
stop() {
    if [ -x "$APP/Contents/MacOS/$NAME" ]; then "$APP/Contents/MacOS/$NAME" --uninstall >/dev/null 2>&1 || true; fi
    pkill -x "$NAME" || true
}

# the one install from before the rename: a LaunchAgent running ~/Applications/UwU Helper.app
migrate() {
    OLD_AGENT="$HOME/Library/LaunchAgents/$ID.plist"
    OLD_APP="$HOME/Applications/UwU Helper.app"
    if [ -e "$OLD_AGENT" ] || [ -e "$OLD_APP" ]; then
        say "moving you over from UwU Helper to Kuro"
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
    reset_grants || say "couldn't reset the old permission grants ( fine on a first install ), if Kuro is already under Accessibility, remove it with the - button first"
    [ -e "$ACTIONS" ] || say "Kuro puts the default Actions file at ~/.config/uwu/actions.json, make it yours!"
    open "$APP" # the first launch adds Kuro to the login items
    say "Kuro is running, and it starts at login from now on"
    say "LAST step: flip the switch next to Kuro in the Accessibility list I just opened ( again after EVERY reinstall )"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    ;;
uninstall)
    stop
    migrate
    rm -rf "$APP"
    reset_grants || true
    say "Kuro is gone, your Actions file is still at ~/.config/uwu/actions.json in case you come back"
    ;;
build)
    build
    say "built into $BUILD, NOTHING got installed"
    ;;
dmg)
    build
    rm -rf "$BUILD/dmg" "$BUILD/$NAME.dmg"
    mkdir -p "$BUILD/dmg"
    ditto "$BUILT" "$BUILD/dmg/$NAME.app"
    ln -s /Applications "$BUILD/dmg/Applications" # so you just drag Kuro onto it
    hdiutil create -quiet -volname "$NAME" -srcfolder "$BUILD/dmg" -format UDZO "$BUILD/$NAME.dmg"
    say "made $BUILD/$NAME.dmg, NOTHING got installed"
    ;;
test)
    need_tools
    mkdir -p "$BUILD"
    swiftc -swift-version 5 helper/core.swift helper/tests.swift -o "$BUILD/tests"
    exec "$BUILD/tests" helper/actions.json
    ;;
*)
    say "usage: ./install.sh [uninstall | build | dmg | test]"
    exit 1
    ;;
esac
