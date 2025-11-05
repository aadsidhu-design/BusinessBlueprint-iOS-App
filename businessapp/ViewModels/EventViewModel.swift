import Foundation
import EventKit

final class EventViewModel {
    private let eventStore = EKEventStore()

    // Function returns true on success, false on any failure.
    func createAllDayEvent(on date: Date, title: String, completion: @escaping (Bool) -> Void) {
        requestAccessIfNeeded { [weak self] granted in
            guard let self = self, granted else {
                completion(false)
                return
            }

            let dayStart = Calendar.current.startOfDay(for: date)

            let event = EKEvent(eventStore: self.eventStore)
            event.title = title
            event.isAllDay = true
            // Per request: start and end on the same calendar day
            event.startDate = dayStart
            event.endDate = dayStart
            event.calendar = self.eventStore.defaultCalendarForNewEvents
                ?? self.eventStore.calendars(for: .event).first(where: { $0.allowsContentModifications })
                ?? self.eventStore.calendars(for: .event).first

            do {
                try self.eventStore.save(event, span: .thisEvent, commit: true)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }

    private func requestAccessIfNeeded(completion: @escaping (Bool) -> Void) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .writeOnly:
            completion(true)
        case .notDetermined:
            eventStore.requestWriteOnlyAccessToEvents() { granted, _ in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        default:
            completion(false)
        }
    }
}
