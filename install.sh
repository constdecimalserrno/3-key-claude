#!/bin/sh
# Builds, installs and starts the UwU Helper. Safe to re-run, updating is git pull + this again.
#
#   ./install.sh             install or update
#   ./install.sh uninstall   remove the Helper, keep your Actions file
#   ./install.sh build       only build, installs NOTHING
#   ./install.sh test        run the Helper core tests
set -eu
cd "$(dirname "$0")"

ID=dev.constdecimalserrno.uwu
NAME="UwU Helper"
# outside the clone, because iCloud ( say a clone in ~/Documents ) tags .app folders and codesign refuses those
BUILD="${TMPDIR:-/tmp}/uwu-build"
BUILT="$BUILD/$NAME.app"
APP="$HOME/Applications/$NAME.app"
AGENT="$HOME/Library/LaunchAgents/$ID.plist"
ACTIONS="$HOME/.config/uwu/actions.json"
DOMAIN="gui/$(id -u)"

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
    say "building the Helper ( takes a few seconds )"
    rm -rf "$BUILT"
    mkdir -p "$BUILT/Contents/MacOS"
    cp helper/Info.plist "$BUILT/Contents/"
    swiftc -O -swift-version 5 -target "$(uname -m)-apple-macos13.0" \
        helper/core.swift helper/main.swift -o "$BUILT/Contents/MacOS/$NAME"
    xattr -cr "$BUILT" # same story for attributes copied over from the clone
    # ponytail: ad-hoc means a brand new identity on EVERY build, so macOS forgets the Accessibility grant each time
    codesign --force --sign - "$BUILT"
    # starts at login, restarts only after a crash
    cat > "$BUILD/$ID.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$ID</string>
	<key>ProgramArguments</key>
	<array>
		<string>$APP/Contents/MacOS/$NAME</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<dict>
		<key>SuccessfulExit</key>
		<false/>
	</dict>
	<key>ProcessType</key>
	<string>Interactive</string>
</dict>
</plist>
EOF
    plutil -lint -s "$BUILD/$ID.plist"
}

stop() { launchctl bootout "$DOMAIN/$ID" >/dev/null 2>&1 || true; }

# the old grants belong to the old build, they are stale now
reset_grants() {
    tccutil reset Accessibility "$ID" >/dev/null 2>&1 && tccutil reset AppleEvents "$ID" >/dev/null 2>&1
}

case "${1:-install}" in
install)
    build
    stop
    say "installing to ~/Applications/$NAME.app"
    mkdir -p "$HOME/Applications"
    rm -rf "$APP"
    ditto "$BUILT" "$APP"
    reset_grants || say "couldn't reset the old permission grants ( fine on a first install ), if UwU Helper is already under Accessibility, remove it with the - button first"
    if [ -e "$ACTIONS" ]; then
        say "keeping your Actions file at ~/.config/uwu/actions.json"
    else
        mkdir -p "$(dirname "$ACTIONS")"
        cp helper/actions.json "$ACTIONS"
        say "put the default Actions file at ~/.config/uwu/actions.json, make it yours!"
    fi
    mkdir -p "$(dirname "$AGENT")"
    cp "$BUILD/$ID.plist" "$AGENT"
    launchctl bootstrap "$DOMAIN" "$AGENT"
    say "the Helper is running, and it starts at login from now on"
    say "LAST step: flip the switch next to UwU Helper in the Accessibility list I just opened ( again after EVERY reinstall )"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    ;;
uninstall)
    stop
    rm -f "$AGENT"
    rm -rf "$APP"
    reset_grants || true
    say "the Helper is gone, your Actions file is still at ~/.config/uwu/actions.json in case you come back"
    ;;
build)
    build
    say "built into $BUILD, NOTHING got installed"
    ;;
test)
    need_tools
    mkdir -p "$BUILD"
    swiftc -swift-version 5 helper/core.swift helper/tests.swift -o "$BUILD/tests"
    exec "$BUILD/tests" helper/actions.json
    ;;
*)
    say "usage: ./install.sh [uninstall | build | test]"
    exit 1
    ;;
esac
