#if os(iOS)
import EventKit
import EventKitUI
import SwiftUI

/// Apple's own "New Event" sheet, filled in with the delivery day. It runs out of process, so no calendar permission prompt.
struct CalendarSheet: UIViewControllerRepresentable {
    let title: String
    let day: Date
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = title
        event.isAllDay = true
        event.startDate = Calendar.current.startOfDay(for: day)
        event.endDate = event.startDate
        let vc = EKEventEditViewController()
        vc.eventStore = store
        vc.event = event
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func eventEditViewController(_ c: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) { dismiss() }
    }
}
#endif
