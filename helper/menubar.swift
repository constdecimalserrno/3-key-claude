// The menu bar icon ( the ONE thing you see of 3KC ) and the 3KC window behind it:
// the Action keys without touching JSON, your folders, Accessibility, and the way back into the Setup window.
// SwiftUI in a plain NSWindow, same as setup.swift.
import AppKit
import SwiftUI

let scriptsFolder = uwuFolder + "/scripts"
let keyGray = Color(red: 0.58, green: 0.58, blue: 0.58) // the icon's gray, #949494
let sides = ["left", "middle", "right"]

// the window's one model, plus the menu bar icon's menu and the window's delegate
final class MenuBar: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = MenuBar()
    @Published var rows: [Entry] = [] // what the window shows, one per Action key ( plus any extras, they get saved as they are )
    @Published private(set) var saved: [Entry]? // what the file says, nil when it isn't a JSON list ( then the window keeps its hands off )
    @Published var note = ""
    @Published var trusted = AXIsProcessTrusted()
    @Published var counting: (row: Int, left: Int)? // a Type Test counting down, so you can click where it should type
    private var text: String? // the file as I read it, so Save notices when you edited it by hand in the meantime
    private var item: NSStatusItem?
    private var window: NSWindow?

    var dirty: Bool { saved != nil && rows != saved }
    var canSave: Bool { saved != nil && (dirty || text == nil) } // no file yet? then Save makes one

    func menuBar() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item?.button?.image = face()
        item?.button?.toolTip = "3-key Claude"
        let menu = NSMenu()
        menu.addItem(withTitle: "Configure keys…", action: #selector(show), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Run setup…", action: #selector(setup), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Open scripts folder", action: #selector(openScripts), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Open Actions file", action: #selector(openActions), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit 3KC", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item?.menu = menu

        // an app without a Dock icon gets no main menu either, and without one cmd-C, cmd-V and cmd-Z do nothing in a text field
        // ponytail: the bare minimum by hand, it's only here for its shortcuts
        let app = NSMenu(), edit = NSMenu(title: "Edit")
        app.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        app.addItem(withTitle: "Quit 3KC", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for (title, action, key) in [("Undo", "undo:", "z"), ("Redo", "redo:", "Z"), ("Cut", "cut:", "x"),
                                     ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector((action)), keyEquivalent: key)
        }
        let bar = NSMenu()
        for sub in [app, edit] {
            let top = NSMenuItem(title: sub.title, action: nil, keyEquivalent: "")
            top.submenu = sub
            bar.addItem(top)
        }
        NSApp.mainMenu = bar
    }

    // Configure keys…, and opening 3-key Claude again from Finder, Launchpad or Spotlight once setup is done
    @objc func show() {
        if window?.isVisible != true { load() } // re-read EVERY time it opens, so hand edits win
        if window == nil {
            window = NSWindow(contentViewController: NSHostingController(rootView: MenuBarWindow(bar: self)))
            window?.title = "3KC"
            window?.styleMask = [.titled, .closable]
            window?.isReleasedWhenClosed = false
            window?.delegate = self
            window?.center()
        }
        trusted = AXIsProcessTrusted()
        NSApp.activate(ignoringOtherApps: true) // no Dock icon, so we pull ourselves up front
        window?.makeKeyAndOrderFront(nil)
    }

    // ponytail: closing with unsaved changes just drops them, the window re-reads the file next time anyway
    func load() {
        text = try? String(contentsOfFile: actionsFile, encoding: .utf8)
        saved = entries(text)
        rows = saved ?? []
        note = text == nil ? "no Actions file yet, Save makes one" : ""
    }

    func save() {
        guard saved != nil else { return }
        // you edited it by hand since I read it, so yours wins and I write NOTHING
        guard (try? String(contentsOfFile: actionsFile, encoding: .utf8)) == text else {
            note = "actions.json changed since I read it, Revert loads yours"
            return
        }
        let new = json(rows)
        do {
            try FileManager.default.createDirectory(atPath: uwuFolder, withIntermediateDirectories: true)
            // not atomic on purpose, so an actions.json that's a symlink into your dotfiles stays one
            try new.write(toFile: actionsFile, atomically: false, encoding: .utf8)
            text = new
            saved = rows
            note = "saved, the keys use it right away"
            log("saved actions.json from the 3KC window")
        } catch { note = "couldn't save - \(error.localizedDescription)" }
    }

    // switching kinds keeps your text, except to and from "as is", that one's the odd entry's JSON and nothing else
    func pick(_ kind: Entry.Kind, _ i: Int) {
        if kind == .odd, let old = saved?[i] { rows[i] = old }
        else if rows[i].kind == .odd { rows[i] = Entry(kind: kind, text: "") }
        else { rows[i].kind = kind }
    }

    // runs what the row says right now, saved or not
    func test(_ i: Int) {
        let key = Key.action(i + 1), effect = decide(key, actionWorld(json(rows)))
        guard case .type = effect else {
            act(effect, key)
            if case .nothing(let why) = effect { note = "did nothing - \(why)" } else { note = "started it" }
            return
        }
        guard AXIsProcessTrusted() else { note = "typing needs Accessibility first, see below"; return }
        counting = (i, 3)
        note = "click where it should type"
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [unowned self] timer in
            if let left = counting?.left, left > 1 { counting?.left = left - 1; return }
            timer.invalidate()
            counting = nil
            // NEVER into this window, it would land right in the field you're editing
            if NSApp.isActive { note = "you stayed in here, so I typed nothing" } else { act(effect, key); note = "typed it" }
        }
    }

    // starts in the scripts folder, and writes the path the short way ( scripts/x.sh, ~/code/x.sh )
    func choose(_ i: Int) {
        guard let window else { return }
        try? FileManager.default.createDirectory(atPath: scriptsFolder, withIntermediateDirectories: true)
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: scriptsFolder)
        panel.message = "Pick a bash or AppleScript file for the \(sides[i]) Action key"
        panel.prompt = "Choose"
        panel.beginSheetModal(for: window) { [self] answer in
            if answer == .OK, let url = panel.url { rows[i].text = shorten(url.path, actionWorld(nil)) }
        }
    }

    @objc func setup() {
        window?.close()
        Setup.shared.step = .welcome
        Setup.shared.show()
    }

    @objc func openScripts() {
        try? FileManager.default.createDirectory(atPath: scriptsFolder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(URL(fileURLWithPath: scriptsFolder))
    }

    func openExamples() {
        let examples = uwuFolder + "/examples"
        NSWorkspace.shared.open(URL(fileURLWithPath: FileManager.default.fileExists(atPath: examples) ? examples : uwuFolder))
    }

    @objc func openActions() { Setup.shared.openActions() }

    // back from System Settings or your editor: fresh Accessibility status, and your hand edits if you have none of mine
    func windowDidBecomeKey(_ n: Notification) {
        trusted = AXIsProcessTrusted()
        if !dirty, (try? String(contentsOfFile: actionsFile, encoding: .utf8)) != text { load() }
    }

    // smart quotes turn the " in a command into curly ones and smart dashes eat the -- of a flag, so a field editor without either
    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? { editor }
    private lazy var editor: NSTextView = {
        let editor = NSTextView()
        editor.isFieldEditor = true
        editor.allowsUndo = true
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticTextReplacementEnabled = false
        editor.isAutomaticSpellingCorrectionEnabled = false
        return editor
    }()
}

// the menu bar icon: the app icon's UwU face, eyes and mouth cut out of a solid circle, as a template image
// so macOS tints it for light and dark menu bars ( the three keys turn to mush at this size, so just the face )
// ponytail: icon.swift's face drawn again here, that one's a script and never part of the app
func face() -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        ctx.translateBy(x: 9, y: 9)
        ctx.addEllipse(in: CGRect(x: -8, y: -8, width: 16, height: 16))
        ctx.fillPath()
        ctx.setBlendMode(.clear) // from here on, drawing cuts holes
        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        for side: CGFloat in [-1, 1] { // the U eyes: down, round the bottom, back up
            ctx.move(to: CGPoint(x: side * 3.3 - 1.4, y: 3.2))
            ctx.addArc(center: CGPoint(x: side * 3.3, y: 1.6), radius: 1.4, startAngle: .pi, endAngle: 0, clockwise: false)
            ctx.addLine(to: CGPoint(x: side * 3.3 + 1.4, y: 3.2))
        }
        ctx.move(to: CGPoint(x: -3, y: -2.2)) // the w mouth, two little bowls side by side
        ctx.addArc(center: CGPoint(x: -1.5, y: -2.2), radius: 1.5, startAngle: .pi, endAngle: 0, clockwise: false)
        ctx.addArc(center: CGPoint(x: 1.5, y: -2.2), radius: 1.5, startAngle: .pi, endAngle: 0, clockwise: false)
        ctx.strokePath()
        return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "3-key Claude"
    return image
}

struct MenuBarWindow: View {
    @ObservedObject var bar: MenuBar

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            loop
            Divider()
            actionKeys
            Divider()
            HStack(alignment: .top, spacing: 24) {
                folders.frame(maxWidth: .infinity, alignment: .leading)
                accessibility.frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            HStack(spacing: 12) {
                Button("Run setup again") { bar.setup() }
                Text("the whole walkthrough, wootility to the last key").foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 700)
    }

    // the UwU's top row, the way it sits on your desk. Read-only, that mapping lives on the UwU itself
    var loop: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    keycap("talk.", "Right Ctrl")
                    keycap("hop.", "F13")
                    keycap("enter.", "Return")
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.black))
                HStack(alignment: .top, spacing: 10) {
                    caption("Talk key", "hold to talk")
                    caption("Cycle key", "next Session")
                    caption("Enter key", "approve")
                }
                .padding(.horizontal, 12)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("These three live on the UwU itself,\nnothing to set in here.").fixedSize(horizontal: false, vertical: true)
                Button("Change them in wootility") { Setup.shared.openWootility() }.buttonStyle(.link)
            }
            .padding(.top, 4)
        }
    }

    func keycap(_ legend: String, _ sends: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(legend).font(.system(size: 17, weight: .semibold, design: .rounded))
            Spacer(minLength: 0)
            Text(sends).font(.system(size: 10, weight: .medium, design: .rounded)).opacity(0.6)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 92, height: 68, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(keyGray))
    }

    func caption(_ name: String, _ does: String) -> some View {
        VStack(spacing: 1) {
            Text(name).font(.callout.weight(.medium))
            Text(does).font(.callout).foregroundStyle(.secondary)
        }
        .frame(width: 92)
    }

    var actionKeys: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Action keys").font(.headline)
                Text("the 3 small ones, left to right").foregroundStyle(.secondary)
            }
            if bar.saved == nil {
                Text("Your actions.json isn't a JSON list, so I'm keeping my hands off it. Fix the typo by hand, then come back.")
                Button("Open Actions file") { bar.openActions() }
            } else {
                ForEach(0..<3, id: \.self) { row($0) }
                HStack(spacing: 8) {
                    Text(bar.note).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button("Revert") { bar.load() }.disabled(!bar.dirty)
                    Button("Save") { bar.save() }.keyboardShortcut("s").buttonStyle(.borderedProminent).disabled(!bar.canSave)
                }
            }
        }
    }

    func row(_ i: Int) -> some View {
        let kind = bar.rows[i].kind
        return HStack(spacing: 10) {
            position(i)
            Picker("", selection: Binding(get: { bar.rows[i].kind }, set: { bar.pick($0, i) })) {
                Text("Type").tag(Entry.Kind.type)
                Text("Run").tag(Entry.Kind.run)
                Text("Script").tag(Entry.Kind.script)
                if bar.saved?[i].kind == .odd { Text("As is").tag(Entry.Kind.odd) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            TextField(hint(kind), text: $bar.rows[i].text)
                .textFieldStyle(.roundedBorder)
                .font(kind == .type ? .body : .callout.monospaced())
                .truncationMode(.head) // the end of a long path is the part that tells your scripts apart
                .disabled(kind == .odd)
                .help(kind == .odd ? "I don't know this kind of entry, so I keep it exactly as it is" : "")
            if kind == .script { Button("Choose…") { bar.choose(i) } }
            Button(bar.counting?.row == i ? "\(bar.counting!.left)…" : "Test") { bar.test(i) }
                .frame(minWidth: 52)
                .disabled(bar.counting != nil || kind == .odd)
        }
    }

    func hint(_ kind: Entry.Kind) -> String {
        switch kind {
        case .type: return "text to type, never a Return"
        case .run: return "a shell command"
        case .script: return "a bash or AppleScript file"
        case .odd: return ""
        }
    }

    // which of the 3 small keys a row is: a tiny pad with that key lit
    func position(_ i: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { k in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(keyGray, lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 2, style: .continuous).fill(k == i ? keyGray : .clear))
                    .frame(width: 9, height: 7)
            }
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.black))
        .help("\(sides[i]) Action key ( F\(16 + i) )")
    }

    var folders: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Folders").font(.headline)
            HStack {
                Button("Scripts") { bar.openScripts() }
                Button("Examples") { bar.openExamples() }
                Button("Actions file") { bar.openActions() }
            }
            Text("Scripts is for your own, Choose… starts there.").font(.callout).foregroundStyle(.secondary)
        }
    }

    var accessibility: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility").font(.headline)
            Label(bar.trusted ? "On, the Action keys can type" : "Off, the Action keys can't type",
                  systemImage: bar.trusted ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(bar.trusted ? Color.green : Color.orange)
            Button("Open Accessibility settings") { Setup.shared.openAccessibility() }
        }
    }
}
