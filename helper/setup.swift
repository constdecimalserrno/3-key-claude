// The Setup window: walks you through the WHOLE setup once ( the UwU too ), with a live check for every key.
// It opens on first launch and whenever you open 3-key Claude while it's already running.
// SwiftUI in a plain NSWindow, so no App, no scenes, no Xcode.
import AppKit
import Carbon.HIToolbox
import SwiftUI

enum Step: Int, CaseIterable { case welcome, uwu, accessibility, talk, terminals, actions, done }

let shareCode = "8ee6080d758ae0da37a7f8b6c9604399d265"
let appNames = ["com.googlecode.iterm2": "iterm2", "com.mitchellh.ghostty": "ghostty"]

func openSettings(_ pane: String) { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:" + pane)!) }

// opened straight from the .dmg ( or from a temporary copy, Gatekeeper's App Translocation ): say so and quit, nothing gets set up from there
func dragMeFirst() -> Never {
    NSApplication.shared.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Drag me into Applications first"
    alert.informativeText = "I'm still running from inside the .dmg. Drag 3-key Claude onto the Applications folder next to me, then open me from Applications."
    alert.runModal()
    exit(0)
}

// the one model: which step you're on and what the live checks saw so far, plus the app's and the window's delegate
final class Setup: NSObject, ObservableObject, NSApplicationDelegate, NSWindowDelegate {
    static let shared = Setup()
    @Published var step = Step.welcome
    @Published var seen: Set<String> = [] // "Enter key", "Talk key", and Key.description for the keys main.swift grabs
    @Published var trusted = AXIsProcessTrusted()
    @Published var swoosh = true // macOS takes you to the Space with the app's windows
    @Published var asked: [String: String] = [:] // bundle id -> how asking for the Automation yes went
    var done: Bool { UserDefaults.standard.bool(forKey: "setupDone") }
    var isOpen: Bool { window?.isVisible == true }
    private var window: NSWindow?
    private var local: Any?, global: Any?, timer: Timer?

    func applicationDidFinishLaunching(_ note: Notification) { if !done { show() } }
    // opened from Finder, Launchpad or Spotlight while already running
    func applicationShouldHandleReopen(_ app: NSApplication, hasVisibleWindows: Bool) -> Bool { show(); return false }

    func show() {
        if window == nil {
            window = NSWindow(contentViewController: NSHostingController(rootView: SetupView(setup: self)))
            window?.title = "3-key Claude"
            window?.styleMask = [.titled, .closable]
            window?.isReleasedWhenClosed = false
            window?.delegate = self
            window?.center()
        }
        if step == .done { step = .welcome } // you finished last time, so start from the top
        if !isOpen { watch() }
        NSApp.activate(ignoringOtherApps: true) // no Dock icon, so we pull ourselves up front
        window?.makeKeyAndOrderFront(nil)
    }

    func close() { window?.close() }

    func windowWillClose(_ note: Notification) {
        if step == .done { UserDefaults.standard.set(true, forKey: "setupDone") }
        [local, global].compactMap { $0 }.forEach(NSEvent.removeMonitor)
        local = nil
        global = nil
        timer?.invalidate()
    }

    func saw(_ check: String) { seen.insert(check) }

    // the Enter key arrives as a plain Return while this window is in front, the Talk key as Right Ctrl from anywhere
    // ponytail: any Return or Right Ctrl ticks the box, your laptop's keys too, so it trusts you a little
    private func watch() {
        local = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [unowned self] event in
            if event.type == .flagsChanged { talk(event); return event }
            guard [kVK_Return, kVK_ANSI_KeypadEnter].contains(Int(event.keyCode)) else { return event }
            saw("Enter key")
            return nil // swallowed, or macOS beeps at you
        }
        listen()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [unowned self] _ in poll() }
        poll()
    }

    // keys pressed in OTHER apps need Accessibility, and a monitor added before you granted it never wakes up, so add it again then
    private func listen() {
        if let global { NSEvent.removeMonitor(global) }
        global = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [unowned self] in talk($0) }
    }

    // Right Ctrl, or Right Option if your dictation app said no to Right Ctrl
    private func talk(_ event: NSEvent) {
        if [kVK_RightControl, kVK_RightOption].contains(Int(event.keyCode)) { saw("Talk key") }
    }

    // once a second while the window is open, both of these get flipped over in System Settings
    private func poll() {
        let now = AXIsProcessTrusted()
        if now != trusted { trusted = now; if now { listen() } }
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)
        let on = CFPreferencesCopyAppValue("workspaces-auto-swoosh" as CFString, "com.apple.dock" as CFString) as? Bool ?? true // missing means on
        if on != swoosh { swoosh = on }
    }

    // asking puts us in the Accessibility list, so there IS a switch to flip ( macOS may pop its own box too, either way works )
    func openAccessibility() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
        openSettings("com.apple.preference.security?Privacy_Accessibility")
    }

    // a harmless Session listing per running terminal app, so macOS pops its one-time Automation prompt NOW,
    // with a whole minute to click Allow ( the Cycle key only waits 2 seconds, see applescript() in main.swift )
    func ask() {
        for app in terminals { asked[app] = "asking, click Allow when macOS asks" }
        // ponytail: the listing holds the main thread ( so this window too ) until you answer, the tiny delay lets "asking" show up first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            for app in terminals {
                if NSRunningApplication.runningApplications(withBundleIdentifier: app).isEmpty {
                    asked[app] = "not running, open it and ask again"
                } else if let listing = applescript(scripts[app]!.list, timeout: 60) {
                    asked[app] = "allowed, \(listing.split(separator: "\n").filter { $0.hasPrefix("session") }.count) Sessions"
                } else {
                    asked[app] = "no luck, turn it on under Automation ( ghostty needs 1.3+ )"
                }
            }
        }
    }

    // safari can't talk to the UwU, so a chromium browser if you have one
    func openWootility() {
        let url = URL(string: "https://wootility.io")!
        let browser = ["com.google.Chrome", "com.microsoft.edgemac", "company.thebrowser.Browser"].lazy
            .compactMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }.first
        if let browser { NSWorkspace.shared.open([url], withApplicationAt: browser, configuration: NSWorkspace.OpenConfiguration()) }
        else { NSWorkspace.shared.open(url) }
    }

    // your editor for .json files, TextEdit if you have none
    // ponytail: TextEdit's smart quotes turn " into curly ones and that breaks JSON, Edit > Substitutions turns them off
    func openActions() {
        let file = URL(fileURLWithPath: actionsFile)
        let editor = NSWorkspace.shared.urlForApplication(toOpen: file) ?? URL(fileURLWithPath: "/System/Applications/TextEdit.app")
        NSWorkspace.shared.open([file], withApplicationAt: editor, configuration: NSWorkspace.OpenConfiguration())
    }
}

// one page per step, Back / Next at the bottom
struct SetupView: View {
    @ObservedObject var setup: Setup
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 10) { page }.fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            HStack {
                Text("step \(setup.step.rawValue + 1) of \(Step.allCases.count)").foregroundStyle(.secondary)
                Spacer()
                if setup.step != .welcome { Button("Back") { setup.step = Step(rawValue: setup.step.rawValue - 1)! } }
                if setup.step == .done { Button("Done") { setup.close() } }
                else { Button("Next") { setup.step = Step(rawValue: setup.step.rawValue + 1)! } }
            }
        }
        .padding(24)
        .frame(width: 560, height: 440)
    }

    @ViewBuilder var page: some View {
        switch setup.step {
        case .welcome:
            heading("talk. hop. enter.")
            Text("Hi, I'm 3-key Claude ( 3KC for short ). Run your ENTIRE agentic workflow from three keys: the Talk key tells a clanker what to do, the Cycle key hops to the next one, the Enter key approves. The 3 small keys below are bonus Actions.")
            Text("I'll walk you through the whole setup right here, the UwU included, with a live check for every key. Plug in your UwU and hit Next, it takes about 5 minutes.")
        case .uwu:
            heading("The UwU")
            Text("""
                1. Open wootility in chrome, edge or arc ( safari can't talk to the UwU ).
                2. My Profiles > Import Profile, paste my share code, Import.
                3. It lands under inactive profiles, drag it into Onboard profiles, slot 1.
                """)
            HStack {
                Text(shareCode).font(.body.monospaced()).textSelection(.enabled)
                Button(copied ? "Copied" : "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(shareCode, forType: .string)
                    copied = true
                }
            }
            Button("Open wootility") { setup.openWootility() }
            check("Enter key ( top-right ), press it with this window in front", setup.seen.contains("Enter key"))
        case .accessibility:
            heading("Accessibility")
            Text("The Action keys type for you, so macOS wants your yes first. Click the button and flip the switch next to 3-key Claude.")
            Text("macOS forgets it after EVERY update, so come back here then. Switch already on but this says off? Remove it with -, then click the button again.")
            Button("Open Accessibility settings") { setup.openAccessibility() }
            check(setup.trusted ? "Accessibility is on" : "Accessibility is off", setup.trusted)
        case .talk:
            heading("The Talk key")
            Text("""
                I use wispr flow, any dictation app that takes Right Ctrl works.
                1. wispr flow's menu bar icon > Settings > General > Shortcuts > Change.
                2. In the Push to talk row click +, press the Talk key ( top-left ), Done. Keep fn.
                """)
            Text("wispr flow says no to Right Ctrl? Give the Talk key Right Option, in wootility AND wispr flow. Shortcuts dead in iterm2? Turn off its Secure Keyboard Entry.")
                .foregroundStyle(.secondary)
            if let wispr = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.electron.wispr-flow") {
                Button("Open wispr flow") { NSWorkspace.shared.openApplication(at: wispr, configuration: NSWorkspace.OpenConfiguration()) }
            }
            check("Talk key ( top-left ), press it", setup.seen.contains("Talk key"))
        case .terminals:
            heading("Your terminals")
            Text("The Cycle key hops through every Session in iterm2 and ghostty. macOS asks ONCE per app if I may, so open the ones you use, click Ask, then Allow.")
            HStack {
                Button("Ask iterm2 and ghostty") { setup.ask() }
                Button("Automation settings") { openSettings("com.apple.preference.security?Privacy_Automation") }
            }
            ForEach(terminals, id: \.self) { app in
                if let how = setup.asked[app] { Text(appNames[app]! + ": " + how).foregroundStyle(.secondary) }
            }
            check(setup.swoosh ? "Spaces: macOS follows you there" : "Spaces: off, turn on \"switch to a Space with open windows\"", setup.swoosh)
            Button("Open Desktop & Dock") { openSettings("com.apple.Desktop-Settings.extension") }
            check("Cycle key ( top-middle ), press it", setup.seen.contains("Cycle key"))
            Text("While I'm open, the Cycle key and Action keys only tick boxes in here.").foregroundStyle(.secondary)
        case .actions:
            heading("The Action keys")
            Text("The 3 small keys each run one Action: a new iterm2 window, typing yes, typing no. Press each one.")
            check("left ( F16 )", setup.seen.contains("Action key 1"))
            check("middle ( F17 )", setup.seen.contains("Action key 2"))
            check("right ( F18 )", setup.seen.contains("Action key 3"))
            Text("Make them yours in `~/.config/uwu/actions.json`, I re-read it on EVERY press.")
            Button("Open Actions file") { setup.openActions() }
        case .done:
            heading("All set!")
            Text("Close me and the keys are yours: talk, hop, enter. I start at login and stay out of your Dock and menu bar.")
            Text("Want this window back? Just open 3-key Claude again. Cheers!")
        }
    }

    func heading(_ text: String) -> some View { Text(text).font(.title2.bold()) }

    func check(_ label: String, _ ok: Bool) -> some View {
        Label(label, systemImage: ok ? "checkmark.circle.fill" : "circle").foregroundStyle(ok ? Color.green : Color.secondary)
    }
}
