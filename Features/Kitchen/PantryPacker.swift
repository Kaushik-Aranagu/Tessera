import Foundation

/// How a place's sections pack into two columns (sheet 234 v4), pure so it tests without a screen. A section is a 26 pt
/// header plus 44 pt rows; a column holds 232 pt. Sections form a queue that starts at the entry section (the first
/// that is low or near its day, wrapping round). Each column takes the head of the queue whole if it fits, else a
/// part of it with an "N more, swipe" row; then any later section that fits whole. A swipe moves both columns on, and
/// Back goes up to six steps back.
struct PantryPacker: Equatable {
    static let capacity: CGFloat = 232
    static let header: CGFloat = 26
    static let row: CGFloat = 44
    static let historyLimit = 6

    struct Section: Equatable {
        let title: String
        let rows: Int
        /// Rows that are low or near their day.
        let urgent: Int
    }

    /// The rows of one section a column shows: `start ..< start + count`, with `more` rows still to come.
    struct Block: Equatable {
        let section: Int
        let start: Int
        let count: Int
        let more: Int

        /// Whole points the block takes: the header, its rows, and the "N more, swipe" row when it is split.
        var height: CGFloat {
            PantryPacker.header + CGFloat(count + (more > 0 ? 1 : 0)) * PantryPacker.row
        }
    }

    typealias Column = [Block]

    private struct Snapshot: Equatable {
        let columns: [Column]
        let queue: [Int]
    }

    let sections: [Section]
    private(set) var columns: [Column]
    /// Sections not yet placed, in order.
    private(set) var queue: [Int]
    private var history: [Snapshot] = []

    /// `columnCount` is 2, or 1 from the first accessibility size (the same rules in one column).
    init(sections: [Section], columnCount: Int = 2) {
        self.sections = sections
        columns = Array(repeating: [], count: columnCount)
        let entry = Self.entry(of: sections)
        queue = sections.indices.map { (entry + $0) % max(sections.count, 1) }.filter { sections[$0].rows > 0 }
        for index in columns.indices {
            columns[index] = takeColumn(continuing: nil, columnsLeft: columns.count - index - 1)
        }
    }

    /// The first section that is low or near its day, else the first.
    static func entry(of sections: [Section]) -> Int {
        sections.firstIndex { $0.urgent > 0 } ?? 0
    }

    // MARK: Packing

    private func fitsWhole(_ rows: Int, in room: CGFloat) -> Bool {
        Self.header + CGFloat(rows) * Self.row <= room
    }

    /// The column that starts with `continuing` (the rest of a split section) or else the head of the queue, then
    /// first-fits later sections that fit whole.
    private mutating func takeColumn(continuing: (section: Int, start: Int)?, columnsLeft: Int) -> Column {
        var column: Column = []
        var used: CGFloat = 0
        var head = continuing
        if head == nil, !queue.isEmpty {
            head = (queue.removeFirst(), 0)
        }
        guard let first = head else { return [] }
        let remaining = sections[first.section].rows - first.start
        if fitsWhole(remaining, in: Self.capacity) {
            let block = Block(section: first.section, start: first.start, count: remaining, more: 0)
            column.append(block)
            used += block.height
        } else {
            // What fits beside the header and the "N more, swipe" row; at least one row.
            let fit = max(1, Int((Self.capacity - Self.header - Self.row) / Self.row))
            let block = Block(section: first.section, start: first.start, count: fit, more: remaining - fit)
            column.append(block)
            return column
        }
        // A column stacks sections only while more are queued than columns are left to fill, so two sections always
        // take both columns.
        var index = 0
        while index < queue.count, queue.count > columnsLeft {
            let entry = queue[index]
            if fitsWhole(sections[entry].rows, in: Self.capacity - used) {
                let block = Block(section: entry, start: 0, count: sections[entry].rows, more: 0)
                column.append(block)
                used += block.height
                queue.remove(at: index)
            } else {
                index += 1
            }
        }
        return column
    }

    // MARK: Steps

    /// Both columns move on: one holding a split section continues it, a finished one packs from the queue, and with
    /// nothing left to place it stays. Whether anything moved.
    @discardableResult
    mutating func advance() -> Bool {
        let before = Snapshot(columns: columns, queue: queue)
        var next = columns
        for index in columns.indices {
            if let split = columns[index].last(where: { $0.more > 0 }) {
                next[index] = takeColumn(continuing: (split.section, split.start + split.count),
                                         columnsLeft: columns.count - index - 1)
            } else if !queue.isEmpty {
                next[index] = takeColumn(continuing: nil, columnsLeft: columns.count - index - 1)
            }
        }
        guard next != columns else {
            queue = before.queue
            return false
        }
        history.append(before)
        if history.count > Self.historyLimit {
            history.removeFirst()
        }
        columns = next
        return true
    }

    /// One step back, if there is one.
    @discardableResult
    mutating func back() -> Bool {
        guard let last = history.popLast() else { return false }
        columns = last.columns
        queue = last.queue
        return true
    }

    /// The title of what the next step brings first: "Next: Produce" or "Next: the rest of Dairy and eggs".
    var nextLine: String? {
        for column in columns {
            if let split = column.last(where: { $0.more > 0 }) {
                return "Next: the rest of \(sections[split.section].title)"
            }
        }
        return queue.first.map { "Next: \(sections[$0].title)" }
    }

    /// VoiceOver for a header: "Dairy and eggs, 5, 2 low".
    func spokenHeader(_ block: Block) -> String {
        let section = sections[block.section]
        let tail = section.urgent > 0 ? ", \(section.urgent) low" : ""
        return "\(section.title), \(section.rows)\(tail)"
    }
}
