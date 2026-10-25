import Foundation

/// The mosaic's own letters (sheet 218): a 3 x 5 face for 0 to 9, A to Z and a few marks, drawn in whole tiles on the
/// window. A digit drawn at scale 2 is 6 x 10 tiles; at scale 1 it is 3 x 5. Pure, so the layout tests read tiles.
enum MosaicPixelFont {
    static let glyphs: [Character: [String]] = {
        var table = MosaicScenes.faces
        let letters: [Character: [String]] = [
            "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"],
            "C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"],
            "E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
            "G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"],
            "I": ["111", "010", "010", "010", "111"], "J": ["001", "001", "001", "101", "010"],
            "K": ["101", "101", "110", "101", "101"], "L": ["100", "100", "100", "100", "111"],
            "M": ["101", "111", "111", "101", "101"], "N": ["110", "101", "101", "101", "101"],
            "O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"],
            "Q": ["010", "101", "101", "110", "011"], "R": ["110", "101", "110", "101", "101"],
            "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"],
            "U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"],
            "W": ["101", "101", "111", "111", "101"], "X": ["101", "101", "010", "101", "101"],
            "Y": ["101", "101", "010", "010", "010"], "Z": ["111", "001", "010", "100", "111"],
            "-": ["000", "000", "111", "000", "000"], ".": ["000", "000", "000", "000", "010"],
            "/": ["001", "001", "010", "100", "100"], "+": ["000", "010", "111", "010", "000"],
        ]
        table.merge(letters) { first, _ in first }
        return table
    }()

    /// Tiles a glyph is wide at `scale`.
    static func width(of character: Character, scale: Int) -> Int {
        character == ":" ? scale : 3 * scale
    }

    /// The width of `text` at `scale`, letters `scale` tiles apart.
    static func width(of text: String, scale: Int) -> Int {
        text.map { width(of: $0, scale: scale) }.reduce(0, +) + max(text.count - 1, 0) * scale
    }

    /// The most letters of `text` that fit `columns` tiles at `scale`; a longer word is cut by whole letters, never
    /// with dots.
    static func fitted(_ text: String, columns: Int, scale: Int) -> String {
        var out = text.uppercased()
        while out.count > 1, width(of: out, scale: scale) > columns {
            out.removeLast()
        }
        return out.trimmingCharacters(in: .whitespaces)
    }

    /// Window-local tiles `text` covers with its top-left at (`left`, `top`). Unknown characters are blank.
    static func tiles(_ text: String, left: Int, top: Int, scale: Int) -> [(column: Int, row: Int)] {
        var x = left
        var out: [(column: Int, row: Int)] = []
        for character in text.uppercased() {
            if character == ":" {
                let dots = scale > 1 ? [2, 3, 6, 7] : [1, 3]
                for dot in dots {
                    for dx in 0 ..< scale {
                        out.append((x + dx, top + dot))
                    }
                }
            } else if let face = glyphs[character] {
                for (rowIndex, line) in face.enumerated() {
                    for (columnIndex, cell) in line.enumerated() where cell == "1" {
                        for dy in 0 ..< scale {
                            for dx in 0 ..< scale {
                                out.append((x + columnIndex * scale + dx, top + rowIndex * scale + dy))
                            }
                        }
                    }
                }
            }
            x += width(of: character, scale: scale) + scale
        }
        return out
    }
}
