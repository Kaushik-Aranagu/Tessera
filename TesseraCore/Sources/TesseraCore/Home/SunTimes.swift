import Foundation

/// Sunrise and sunset worked out on the phone (Home mosaic, sheet 199). Nothing is looked up and nothing is sent: the
/// caller passes a coarse place (a degree or so is plenty) or just the time zone. The place is rounded to a tenth of a
/// degree before use and never stored, logged or passed on.
public enum SunTimes {
    public struct Day: Equatable, Sendable {
        public let sunrise: Date
        public let sunset: Date
    }

    /// NOAA's sunrise equation, good to a couple of minutes. Nil in polar day or night.
    public static func day(latitude: Double, longitude: Double, on date: Date, calendar: Calendar = .current) -> Day? {
        let latitude = (latitude * 10).rounded() / 10, longitude = (longitude * 10).rounded() / 10
        guard abs(latitude) <= 90, abs(longitude) <= 180,
              let rise = event(rising: true, latitude: latitude, longitude: longitude, on: date, calendar: calendar),
              let set = event(rising: false, latitude: latitude, longitude: longitude, on: date, calendar: calendar)
        else { return nil }
        return Day(sunrise: rise, sunset: set)
    }

    /// With no place at all: the middle of the time zone's band of longitude at 38 degrees north, which is near enough
    /// to draw a sky and is never shown as a time he is told. Falls back to 6:30 am and 6:30 pm in polar cases.
    public static func approximate(on date: Date, calendar: Calendar = .current) -> Day {
        let longitude = Double(calendar.timeZone.secondsFromGMT(for: date)) / 3600 * 15
        if let day = day(latitude: 38, longitude: longitude, on: date, calendar: calendar) {
            return day
        }
        let start = calendar.startOfDay(for: date)
        return Day(sunrise: start.addingTimeInterval(6.5 * 3600), sunset: start.addingTimeInterval(18.5 * 3600))
    }

    private static func event(rising: Bool, latitude: Double, longitude: Double, on date: Date, calendar: Calendar)
        -> Date?
    {
        let radians = Double.pi / 180
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let midnightUTC = utc.date(from: parts), let year = parts.year,
              let jan1 = utc.date(from: DateComponents(year: year, month: 1, day: 1)),
              let n = utc.dateComponents([.day], from: jan1, to: midnightUTC).day.map({ Double($0 + 1) })
        else { return nil }
        let lngHour = longitude / 15
        let t = n + ((rising ? 6 : 18) - lngHour) / 24
        let m = 0.9856 * t - 3.289
        var l = m + 1.916 * sin(m * radians) + 0.020 * sin(2 * m * radians) + 282.634
        l = l.truncatingRemainder(dividingBy: 360)
        if l < 0 {
            l += 360
        }
        var ra = atan(0.91764 * tan(l * radians)) / radians
        ra = ra.truncatingRemainder(dividingBy: 360)
        if ra < 0 {
            ra += 360
        }
        ra += (floor(l / 90) * 90) - (floor(ra / 90) * 90)
        ra /= 15
        let sinDec = 0.39782 * sin(l * radians)
        let cosDec = cos(asin(sinDec))
        let cosH = (cos(90.833 * radians) - sinDec * sin(latitude * radians)) / (cosDec * cos(latitude * radians))
        guard cosH >= -1, cosH <= 1 else { return nil }
        let h = (rising ? 360 - acos(cosH) / radians : acos(cosH) / radians) / 15
        let localMean = h + ra - 0.06571 * t - 6.622
        var ut = (localMean - lngHour).truncatingRemainder(dividingBy: 24)
        if ut < 0 {
            ut += 24
        }
        var result = midnightUTC.addingTimeInterval(ut * 3600)
        // Keep it within half a day of local noon, so a far-east or far-west place gets its own day's event.
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        while result.timeIntervalSince(noon) > 12 * 3600 {
            result.addTimeInterval(-86400)
        }
        while noon.timeIntervalSince(result) > 12 * 3600 {
            result.addTimeInterval(86400)
        }
        return result
    }
}
