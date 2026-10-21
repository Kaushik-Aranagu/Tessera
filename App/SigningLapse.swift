import Foundation

/// The free developer account's build stops opening when its provisioning profile ends, seven days after each install
/// (G693, hunt 28 CALL 7 A). A day or two before, Now says so quietly, read from the profile inside the app. The
/// simulator has no profile, so nothing shows there unless `-signingLapseDays 1` asks for it.
enum SigningLapse {
    /// The warning shows this long before the end and no earlier.
    static let lead: TimeInterval = 2 * 24 * 60 * 60

    /// When this build stops opening: the profile's ExpirationDate, or on the simulator now plus the flag's days.
    static func expiry(now: Date, lapseDays: Double? = LaunchFlags.signingLapseDays) -> Date? {
        if let days = lapseDays {
            return now.addingTimeInterval(days * 24 * 60 * 60)
        }
        return profileExpiry
    }

    /// Read once per run: the profile never changes while the app is open.
    static let profileExpiry: Date? = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision")
        .flatMap { try? Data(contentsOf: $0) }
        .flatMap(expiry(fromProfile:))

    /// The ExpirationDate inside an embedded.mobileprovision: a signed envelope around an XML plist, so the plist is
    /// cut out from "<?xml" to "</plist>" and read. Nil when it isn't there or can't be read.
    static func expiry(fromProfile data: Data) -> Date? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound ..< data.endIndex)
        else { return nil }
        let plist = data.subdata(in: start.lowerBound ..< end.upperBound)
        let object = try? PropertyListSerialization.propertyList(from: plist, format: nil)
        return (object as? [String: Any])?["ExpirationDate"] as? Date
    }

    /// The quiet line, or nil: only inside the last two days, never after the end (a lapsed build doesn't open).
    static func warning(expiry: Date?, now: Date, calendar: Calendar = .current) -> String? {
        guard let expiry else { return nil }
        let left = expiry.timeIntervalSince(now)
        guard left > 0, left <= lead else { return nil }
        return line(expiry: expiry, now: now, calendar: calendar)
    }

    /// "This build stops opening tomorrow at 6:36 AM. Your data stays on this iPhone."
    static func line(expiry: Date, now: Date, calendar: Calendar = .current) -> String {
        let day = calendar.isDate(expiry, inSameDayAs: now) ? "today"
            : calendar.isDate(expiry, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
            ? "tomorrow" : weekday(expiry, calendar: calendar)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "h:mm a"
        return "This build stops opening \(day) at \(formatter.string(from: expiry)). Your data stays on this iPhone."
    }

    private static func weekday(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

extension LaunchFlags {
    /// `-signingLapseDays 1`: on the simulator, pretend the build stops opening this many days from now.
    nonisolated static var signingLapseDays: Double? {
        value(after: "-signingLapseDays").flatMap(Double.init)
    }
}
