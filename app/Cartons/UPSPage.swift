import Foundation
import WebKit

/// Reads UPS's public tracking page in a hidden web view, the way a person would.
/// No API keys: ups.com blocks plain HTTP, but a real WebKit view passes.
// ponytail: tied to the page's visible text, breaks if UPS rewords it; the official API is the upgrade once keys exist
@MainActor
final class UPSPage: NSObject {
    enum Failure: LocalizedError {
        case notFound, timedOut
        var errorDescription: String? {
            self == .notFound ? "UPS can't find this number yet." : "UPS didn't answer. Pull to retry."
        }
    }

    private var web: WKWebView?

    func fetch(_ number: String) async throws -> Status {
        let web = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        self.web = web
        defer { self.web = nil }
        web.load(URLRequest(url: URL(string: "https://www.ups.com/track?loc=en_US&tracknum=\(number)&requester=ST/trackdetails")!))

        for _ in 0..<40 {  // up to 20s for the page's scripts to fill in the result
            try await Task.sleep(for: .milliseconds(500))
            // open "Shipment Details" so service and destination render
            _ = try? await web.evaluateJavaScript("document.querySelectorAll('button').forEach(b=>{if(/^\\s*shipment details/i.test(b.innerText)&&b.getAttribute('aria-expanded')!=='true')b.click()})")
            let text = (try? await web.evaluateJavaScript("document.body ? document.body.innerText : ''")) as? String ?? ""
            if UPSPage.isNotFound(text) { throw Failure.notFound }
            if let s = UPSPage.parse(text, number: number) { return s }
        }
        throw Failure.timedOut
    }

    nonisolated static let headlines = ["delivered", "out for delivery", "on the way", "we have your package", "label created",
                                        "delivery attempted", "exception", "delayed", "returned to sender", "returning to sender",
                                        "held", "ready for pickup", "in transit"]

    nonisolated static func isNotFound(_ text: String) -> Bool {
        let t = text.lowercased()
        return t.contains("could not locate the shipment") || t.contains("tracking number is invalid") || t.contains("unable to find")
    }

    /// Pulls status, ETA and last scan out of the page text. Nil until the result has rendered.
    nonisolated static func parse(_ text: String, number: String) -> Status? {
        // UPS's icons render as words in the text (check_circle, chevron_right, help): drop them first
        let icons: Set<String> = ["help", "close", "check", "lock", "info", "search", "menu"]
        let lines = text.split(separator: "\n")
            .map { $0.replacingOccurrences(of: "\\b[a-z]+(?:_[a-z]+)+\\b", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !icons.contains($0) }
        let lower = lines.map { $0.lowercased() }
        let squash = { (s: String) in s.replacingOccurrences(of: " ", with: "").uppercased() }
        // the result has rendered once our number and a date label are both on the page
        guard lines.contains(where: { squash($0) == squash(number) }) else { return nil }
        let dateLabels = ["estimated delivery", "scheduled delivery", "delivered on", "delivery date", "delivered"]
        guard lower.contains(where: { l in dateLabels.contains { l.hasPrefix($0) } }) else { return nil }

        // the progress bar marks the current step with "active" on the next line; otherwise take the first known headline
        let active = zip(lines, lower.dropFirst()).first { $0.1 == "active" }?.0
        let headline = lines.first { l in headlines.contains { l.lowercased().hasPrefix($0) } }
        let status = active ?? headline ?? "In transit"
        let delivered = status.lowercased().hasPrefix("delivered") || lower.contains { $0.hasPrefix("delivered on") }

        // value for a label: same-line text after a colon, else the next line that isn't a help icon
        func value(_ labels: [String]) -> String? {
            for label in labels {
                guard let j = lower.firstIndex(where: { $0.hasPrefix(label) }) else { continue }
                let rest = lines[j].dropFirst(label.count).trimmingCharacters(in: CharacterSet(charactersIn: ": "))
                if !rest.isEmpty { return rest }
                if let next = lines[(j + 1)...].first { return next }
            }
            return nil
        }
        let eta = delivered ? value(["delivered on", "delivery date", "delivered"]) : value(["estimated delivery", "scheduled delivery", "delivery date"])
        // the progress bar: each step name is followed by its state
        var steps = zip(lines, lower.dropFirst()).filter { ["completed", "active", "inactive"].contains($0.1) }.map { Step(name: $0.0, state: $0.1) }
        // the phone layout lists them last step first; always read first step first
        if steps.first?.state == "inactive" || steps.last?.state == "completed" && steps.first?.state != "completed" { steps.reverse() }
        return Status(number: number, status: status, eta: eta, etaDate: eta.flatMap { day($0) }, delivered: delivered,
                      lastLocation: value(["last location"]), service: value(["service"]), shipTo: value(["ship to"]), steps: steps)
    }

    /// "Tuesday, October 27 , 9:30 A.M.", "10/27/2026", "Today" or "Tomorrow" -> that day.
    nonisolated static func day(_ s: String, now: Date = .now) -> Date? {
        let cal = Calendar.current
        let l = s.lowercased()
        if l.hasPrefix("today") { return cal.startOfDay(for: now) }
        if l.hasPrefix("tomorrow") { return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        if let r = s.range(of: "\\d{1,2}/\\d{1,2}/\\d{4}", options: .regularExpression) {
            f.dateFormat = "M/d/yyyy"
            return f.date(from: String(s[r]))
        }
        guard let r = s.range(of: "(January|February|March|April|May|June|July|August|September|October|November|December) \\d{1,2}", options: .regularExpression) else { return nil }
        f.dateFormat = "MMMM d yyyy"
        guard let d = f.date(from: "\(s[r]) \(cal.component(.year, from: now))") else { return nil }
        // a January ETA seen in December belongs to next year
        return d < now.addingTimeInterval(-180 * 86400) ? cal.date(byAdding: .year, value: 1, to: d) : d
    }
}
