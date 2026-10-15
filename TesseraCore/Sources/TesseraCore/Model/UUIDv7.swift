import Foundation

public extension UUID {
    /// A version 7 UUID (RFC 9562): 48 bits of Unix milliseconds, then random bits. Ids sort by creation time,
    /// merge safely across devices, and index well. Assigned on device; never reused.
    static func v7(at date: Date = .now) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let milliseconds = UInt64(max(0, date.timeIntervalSince1970 * 1000))
        for index in 0 ..< 6 {
            bytes[index] = UInt8(truncatingIfNeeded: milliseconds >> UInt64(8 * (5 - index)))
        }
        var generator = SystemRandomNumberGenerator()
        for index in 6 ..< 16 {
            bytes[index] = UInt8.random(in: .min ... .max, using: &generator)
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x70 // version 7
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // RFC 4122 variant
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    /// The creation time of a version 7 UUID, else nil.
    var v7Date: Date? {
        let bytes = uuid
        guard bytes.6 >> 4 == 7 else { return nil }
        let parts = [bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5]
        let milliseconds = parts.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
    }
}
