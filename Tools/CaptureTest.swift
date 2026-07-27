import Cocoa
import ApplicationServices

// Shows exactly what MitthuAI sees on your screen, and what it would make of
// every line — so a missed mail or a nonsense deadline stops being guesswork.
//
//   swiftc -O Tools/CaptureTest.swift Sources/MitthuAI/DateParse.swift -o /tmp/capture
//   /tmp/capture            # switch to the window you want to inspect
//
// Verdicts come from DateParse itself, the same code the app runs — this tool
// links it rather than reimplementing it, so it can't drift.

let delay = CommandLine.arguments.count > 1 ? (Int(CommandLine.arguments[1]) ?? 5) : 5
let outPath = NSString(string: "~/Desktop/mitthuai-capture.txt").expandingTildeInPath

guard AXIsProcessTrusted() else {
    print("""
    Accessibility permission is needed to read window text.
    System Settings → Privacy & Security → Accessibility → add Terminal (or your
    terminal app), then run this again.
    """)
    exit(1)
}

print("Switch to the window you want to capture (a mail, a lecture page…).")
for i in stride(from: delay, to: 0, by: -1) {
    print("  capturing in \(i)…")
    fflush(stdout)
    Thread.sleep(forTimeInterval: 1)
}

// MARK: - A compact copy of AXReader's walk (AXReader itself pulls in Config)

func attr(_ el: AXUIElement, _ name: String) -> CFTypeRef? {
    var ref: CFTypeRef?
    return AXUIElementCopyAttributeValue(el, name as CFString, &ref) == .success ? ref : nil
}
func str(_ el: AXUIElement, _ name: String) -> String? { attr(el, name) as? String }

func walk(_ window: AXUIElement) -> (text: [String], controls: [String]) {
    var text: [String] = [], controls: [String] = []
    var visited = 0
    let textRoles: Set<String> = ["AXStaticText", "AXTextField", "AXTextArea", "AXHeading",
                                  "AXLink", "AXCell", "AXComboBox", "AXPopUpButton"]
    let controlRoles: Set<String> = ["AXButton", "AXSlider", "AXMenuButton"]

    func visit(_ el: AXUIElement, _ depth: Int) {
        if depth > 30 || visited > 3000 { return }
        visited += 1
        let role = str(el, kAXRoleAttribute as String) ?? ""
        if let sub = str(el, kAXSubroleAttribute as String), sub == "AXSecureTextField" { return }

        if textRoles.contains(role) {
            var v = ""
            if let s = attr(el, kAXValueAttribute as String) as? String { v = s }
            else if let t = str(el, kAXTitleAttribute as String) { v = t }
            let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.count > 1 { text.append(t) }
        } else if controlRoles.contains(role) {
            var parts: [String] = []
            for name in [kAXTitleAttribute as String, kAXDescriptionAttribute as String,
                         kAXValueDescriptionAttribute as String] {
                if let s = str(el, name), !s.isEmpty { parts.append(s) }
            }
            if let v = attr(el, kAXValueAttribute as String) as? String, !v.isEmpty { parts.append(v) }
            let joined = parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if joined.count > 1 { controls.append(joined) }
        }
        if let kids = attr(el, kAXChildrenAttribute as String) as? [AXUIElement] {
            for k in kids.prefix(120) { visit(k, depth + 1) }
        }
    }
    visit(window, 0)
    return (text, controls)
}

func browserURL(_ bundleId: String) -> String? {
    let source: String
    switch bundleId {
    case "com.apple.Safari", "com.apple.SafariTechnologyPreview":
        source = "tell application id \"\(bundleId)\" to return URL of front document"
    case "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac",
         "com.vivaldi.Vivaldi", "company.thebrowser.Browser":
        source = "tell application id \"\(bundleId)\" to return URL of active tab of front window"
    default: return nil
    }
    var err: NSDictionary?
    return NSAppleScript(source: source)?.executeAndReturnError(&err).stringValue
}

// MARK: - Capture

guard let app = NSWorkspace.shared.frontmostApplication else {
    print("No frontmost app."); exit(1)
}
let pid = app.processIdentifier
let appRef = AXUIElementCreateApplication(pid)
let window = (attr(appRef, kAXFocusedWindowAttribute as String)
              ?? attr(appRef, kAXMainWindowAttribute as String)).map { $0 as! AXUIElement }

guard let win = window else {
    print("Could not read a window from \(app.localizedName ?? "that app")."); exit(1)
}

let title = str(win, kAXTitleAttribute as String) ?? ""
let (lines, controls) = walk(win)
let url = browserURL(app.bundleIdentifier ?? "")

var out = ""
func emit(_ s: String = "") { out += s + "\n"; print(s) }

emit("MitthuAI capture — \(DateParse.isoDay(Date())) \(Date())")
emit(String(repeating: "=", count: 72))
emit("App        : \(app.localizedName ?? "?")  [\(app.bundleIdentifier ?? "?")]")
emit("Window     : \(title)")
emit("URL        : \(url ?? "(none — this app exposes no URL)")")
emit("Text lines : \(lines.count)    Control labels: \(controls.count)")
emit()

emit("WHAT WOULD BECOME A BRAIN ITEM")
emit(String(repeating: "-", count: 72))
var candidates = 0
for (i, line) in lines.enumerated() {
    let next = i + 1 < lines.count ? lines[i + 1] : nil
    let gate = DateParse.candidateReason(in: line)
    guard let reason = gate else { continue }
    candidates += 1
    emit("line \(i): \(line.prefix(150))")
    emit("   gate  : \(reason)")
    if let f = DateParse.dueDate(in: line, nextLine: next) {
        emit("   date  : \(DateParse.isoDay(Date(timeIntervalSince1970: f.ts))) "
             + "from \"\(f.matched)\" via \(f.via)\(f.ambiguous ? " (ambiguous)" : "")")
    } else {
        emit("   date  : none found → no item created")
    }
    if let why = DateParse.rejectionReason(in: line) {
        emit("   DROPPED: \(why)")
    }
    emit()
}
if candidates == 0 { emit("(no line on this screen looks like a deadline)"); emit() }

emit("ALL TEXT LINES AS CAPTURED")
emit(String(repeating: "-", count: 72))
for (i, line) in lines.enumerated() { emit("\(i): \(line)") }
emit()
emit("CONTROL LABELS (buttons, sliders — how a video player is spotted)")
emit(String(repeating: "-", count: 72))
for c in controls { emit("· \(c)") }

try? out.write(toFile: outPath, atomically: true, encoding: .utf8)
print("\nSaved to \(outPath) — send that file over and the extraction can be tuned on real text.")
