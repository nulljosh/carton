// Runnable check for the UPS page parser: tests/run.sh
import Foundation

@main
struct ParseCheck {
    static func main() {
        let n = "1ZG2C4706800239082"
        // real desktop page text, captured 2026-10-20
        let onTheWay = """
        Tracking Details
        On the Way
        \(n)
        Estimated delivery
         help
        Tuesday, October 27 , 9:30 A.M. - 12:30 P.M.
        Last Location:
        Hodgkins, IL, United States, 10/20/2026, 9:56 A.M.
        Label Created
        completed
        We Have Your Package
        completed
        On the Way
        active
        Out for Delivery
        inactive
        Ship To
        LANGLEY, BC CA
        Service
        UPS® Standard
        """
        let s = UPSPage.parse(onTheWay, number: n)!
        assert(s.status == "On the Way", s.status)
        assert(s.eta == "Tuesday, October 27 , 9:30 A.M. - 12:30 P.M.")
        assert(Calendar.current.component(.day, from: s.etaDate!) == 27)
        assert(s.lastLocation?.hasPrefix("Hodgkins") == true && s.shipTo == "LANGLEY, BC CA" && s.service == "UPS® Standard")
        assert(!s.delivered)
        assert(s.steps.map(\.name) == ["Label Created", "We Have Your Package", "On the Way", "Out for Delivery"])
        assert(s.steps.map(\.state) == ["completed", "completed", "active", "inactive"])

        // mobile layout: no status line before the number, headline found via the active step
        let mobile = onTheWay.replacingOccurrences(of: "Tracking Details\nOn the Way\n", with: "Tracking Details\n")
        assert(UPSPage.parse(mobile, number: n)?.status == "On the Way")

        // phone layout lists steps last first
        let flipped = "\(n)\nEstimated delivery\nTomorrow\nDelivery\ninactive\nOn the Way\nactive\nLabel Created\ncompleted"
        assert(UPSPage.parse(flipped, number: n)!.steps.map(\.name) == ["Label Created", "On the Way", "Delivery"])

        // delivered, date on the same line as its label
        let done = "Delivered\n\(n)\nDelivered On: Tuesday, 10/27/2026 at 11:02 A.M.\nShip To\nLANGLEY, BC CA"
        let d = UPSPage.parse(done, number: n)!
        assert(d.delivered && d.status == "Delivered")
        assert(Calendar.current.component(.month, from: d.etaDate!) == 10)

        // icon names leak into the text as words
        let icons = "Delivered check_circle\n\(n)\nDelivered On\ncheck_circle\nMonday, 10/12/2026 at 2:14 P.M.\nchevron_right\nhelp"
        let ic = UPSPage.parse(icons, number: n)!
        assert(ic.status == "Delivered" && ic.eta == "Monday, 10/12/2026 at 2:14 P.M.", "\(ic.status) / \(ic.eta ?? "nil")")

        // still loading: nothing yet
        assert(UPSPage.parse("Tracking Details\nLoading", number: n) == nil)
        assert(UPSPage.isNotFound("We could not locate the shipment details for this tracking number."))

        // relative and year-wrapping dates
        let dec = DateComponents(calendar: .current, year: 2026, month: 12, day: 30).date!
        assert(Calendar.current.component(.year, from: UPSPage.day("Friday, January 2", now: dec)!) == 2027)
        assert(UPSPage.day("Tomorrow, 9:30 A.M.", now: dec) == Calendar.current.date(byAdding: .day, value: 1, to: dec))
        print("parse check ok")
    }
}
