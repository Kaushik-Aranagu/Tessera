import EventKit
import Foundation
import TesseraCore

/// The calendar mount's one reader of EventKit (M4 slice 1): turns the window's events into `CalendarEventInput`s
/// and runs `SyncCalendar`. It never prompts by itself: `requestAccess()` is called from his tap on "Connect
/// calendar", and `refresh` on foreground, on a store change and on a time zone change does nothing unless access is
/// already full. Write-only access reads nothing (calling `events(matching:)` there would raise the system upgrade
/// prompt, so it is never called).
@MainActor
final class CalendarMounter {
    private let store = EKEventStore()
    private let engine: ActionEngine

    /// Yesterday to 14 days ahead.
    static func window(now: Date, calendar: Calendar) -> (start: Date, end: Date) {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 15, to: today) ?? today
        return (start, end)
    }

    init(engine: ActionEngine) {
        self.engine = engine
    }

    var access: CalendarAccess {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: .fullAccess
        case .writeOnly: .writeOnly
        case .denied: .denied
        case .restricted: .restricted
        default: .notDetermined
        }
    }

    /// From his tap only.
    func requestAccess() async -> CalendarAccess {
        _ = try? await store.requestFullAccessToEvents()
        return access
    }

    /// Mirrors the window. Returns what changed; nothing at all without full access.
    @discardableResult
    func refresh(now: Date = .now, calendar: Calendar = .current) -> SyncCalendar.Result? {
        let access = access
        guard access == .fullAccess else {
            return try? engine.perform(SyncCalendar(inputs: [], windowStart: now, windowEnd: now, access: access),
                                       by: .system).output
        }
        let range = Self.window(now: now, calendar: calendar)
        let predicate = store.predicateForEvents(withStart: range.start, end: range.end, calendars: nil)
        let inputs = store.events(matching: predicate).map(Self.input)
        return try? engine.perform(SyncCalendar(inputs: inputs, windowStart: range.start, windowEnd: range.end,
                                                access: .fullAccess), by: .system).output
    }

    private static func input(_ event: EKEvent) -> CalendarEventInput {
        let own = event.attendees?.first(where: \.isCurrentUser)
        let status: EventAttendance = switch own?.participantStatus {
        case .accepted: .accepted
        case .declined: .declined
        case .tentative: .tentative
        case .pending: .pending
        default: .unknown
        }
        let availability: EventAvailability = switch event.availability {
        case .free: .free
        case .tentative: .tentative
        case .unavailable: .unavailable
        default: .busy
        }
        return CalendarEventInput(
            externalID: event.calendarItemExternalIdentifier ?? event.eventIdentifier ?? UUID().uuidString,
            title: event.title ?? "", start: event.startDate, end: event.endDate ?? event.startDate,
            occurrenceDate: event.occurrenceDate, isAllDay: event.isAllDay, timeZone: event.timeZone?.identifier,
            isRecurring: event.hasRecurrenceRules, isDetached: event.isDetached, isCancelled: event.status == .canceled,
            availability: availability, calendarName: event.calendar?.title ?? "",
            calendarIsBirthday: event.calendar?.type == .birthday,
            calendarIsMine: event.calendar?.allowsContentModifications ?? false, selfStatus: status,
            location: event.location, birthdayContactID: event.birthdayContactIdentifier
        )
    }
}
