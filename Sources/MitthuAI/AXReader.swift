import Cocoa
import ApplicationServices

struct AXSnapshot {
    let appName: String
    let bundleId: String
    let windowTitle: String
    let text: String
    let url: String?
}

/// Reads the frontmost window through the macOS Accessibility API — the same
/// tree VoiceOver walks — so we get real text without screenshots.
enum AXReader {

    static func attr(_ el: AXUIElement, _ name: String) -> CFTypeRef? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(el, name as CFString, &ref)
        return result == .success ? ref : nil
    }

    static func string(_ el: AXUIElement, _ name: String) -> String? {
        return attr(el, name) as? String
    }

    static func focusedWindow(pid: pid_t) -> AXUIElement? {
        let appRef = AXUIElementCreateApplication(pid)
        if let w = attr(appRef, kAXFocusedWindowAttribute as String) {
            return (w as! AXUIElement)
        }
        if let w = attr(appRef, kAXMainWindowAttribute as String) {
            return (w as! AXUIElement)
        }
        return nil
    }

    static func frontmostDetails() -> (app: NSRunningApplication, window: AXUIElement?, title: String)? {
        guard let front = NSWorkspace.shared.frontmostApplication else { return nil }
        let window = focusedWindow(pid: front.processIdentifier)
        var title = ""
        if let w = window, let t = string(w, kAXTitleAttribute as String) {
            title = t
        }
        return (front, window, title)
    }

    /// Walk the AX tree of a window collecting user-visible text.
    /// Depth/node/char limited so a huge web page can't stall the app.
    static func extractText(from window: AXUIElement, maxChars: Int = 24000) -> String {
        var pieces: [String] = []
        var totalChars = 0
        var visited = 0

        let textRoles: Set<String> = [
            "AXStaticText", "AXTextField", "AXTextArea", "AXHeading",
            "AXLink", "AXCell", "AXComboBox", "AXPopUpButton"
        ]

        func walk(_ el: AXUIElement, depth: Int) {
            if depth > 30 || visited > 3000 || totalChars >= maxChars { return }
            visited += 1

            let role = string(el, kAXRoleAttribute as String) ?? ""

            // Never read secure fields (passwords etc.)
            if let subrole = string(el, kAXSubroleAttribute as String), subrole == "AXSecureTextField" {
                return
            }

            if textRoles.contains(role) {
                var value = ""
                if let v = attr(el, kAXValueAttribute as String) as? String {
                    value = v
                } else if let t = string(el, kAXTitleAttribute as String) {
                    value = t
                }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 1 {
                    let clipped = String(trimmed.prefix(maxChars - totalChars))
                    pieces.append(clipped)
                    totalChars += clipped.count + 1
                }
            }

            if totalChars >= maxChars { return }
            if let children = attr(el, kAXChildrenAttribute as String) as? [AXUIElement] {
                for child in children.prefix(120) {
                    walk(child, depth: depth + 1)
                    if totalChars >= maxChars || visited > 3000 { break }
                }
            }
        }

        walk(window, depth: 0)
        return pieces.joined(separator: "\n")
    }

    /// Current URL of the frontmost browser tab, via Apple Events.
    /// Requires the Automation permission (prompted on first use).
    static func browserURL(bundleId: String) -> String? {
        let source: String
        switch bundleId {
        case "com.apple.Safari", "com.apple.SafariTechnologyPreview":
            source = "tell application id \"\(bundleId)\" to return URL of front document"
        case "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac",
             "com.vivaldi.Vivaldi", "company.thebrowser.Browser":
            source = "tell application id \"\(bundleId)\" to return URL of active tab of front window"
        default:
            return nil
        }

        var url: String? = nil
        let work = {
            guard let script = NSAppleScript(source: source) else { return }
            var error: NSDictionary?
            let result = script.executeAndReturnError(&error)
            if error == nil {
                url = result.stringValue
            }
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.sync(execute: work) }
        return url
    }

    static func isPrivateWindow(title: String) -> Bool {
        let t = title.lowercased()
        return t.contains("private browsing") || t.contains("incognito") || t.contains("(private)")
    }

    /// One full snapshot of the frontmost window: app, title, text, url.
    static func snapshot(captureText: Bool, captureURL: Bool) -> AXSnapshot? {
        guard let (app, window, title) = frontmostDetails() else { return nil }
        let appName = app.localizedName ?? "Unknown"
        let bundleId = app.bundleIdentifier ?? ""

        if Config.shared.isExcluded(app: appName) {
            return AXSnapshot(appName: appName, bundleId: bundleId, windowTitle: title, text: "", url: nil)
        }
        if isPrivateWindow(title: title) {
            return AXSnapshot(appName: appName, bundleId: bundleId, windowTitle: title, text: "", url: nil)
        }

        var text = ""
        if captureText, let w = window {
            text = extractText(from: w)
        }
        var url: String? = nil
        if captureURL {
            url = browserURL(bundleId: bundleId)
        }
        return AXSnapshot(appName: appName, bundleId: bundleId, windowTitle: title, text: text, url: url)
    }
}
