import Foundation

/// Builds a shareable sticker list (the Missing list on the Album tab, or the
/// Duplicates list on the Duplicates tab) in two renderings that share the same
/// structure: a CSV file and a paste-ready grouped text block.
struct StickerExportList {
    let title: String           // "WC26 Album — Missing" / "WC26 Album — Duplicates"
    let items: [Item]
    /// Duplicates show "×N" spares in the text rendering; Missing does not.
    let showQuantityInText: Bool

    struct Item {
        let code: String
        let number: Int
        let name: String
        let team: String
        let section: String
        let isFoil: Bool
        let quantity: Int       // Missing: 1 (needed). Duplicates: spares (count-1).
    }

    // MARK: - Text (paste into a messaging app)

    func plainText() -> String {
        var lines: [String] = []
        let headerCount = showQuantityInText
            ? String(localized: "\(items.reduce(0) { $0 + $1.quantity }) spare")
            : "\(items.count)"
        lines.append("\(title) (\(headerCount))")
        lines.append("")

        for (section, group) in groupedBySection() {
            let codes = group.map { item -> String in
                showQuantityInText && item.quantity > 1 ? "\(item.code) ×\(item.quantity)" : item.code
            }
            lines.append("\(section.localizedName): \(codes.joined(separator: ", "))")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - CSV

    func csv() -> String {
        var rows = ["Code,Number,Name,Team,Section,Type,Quantity"]
        for item in items {
            let fields = [
                item.code,
                String(item.number),
                item.name,
                item.team,
                item.section,
                item.isFoil ? "Brilliant" : "Common",
                String(item.quantity),
            ]
            rows.append(fields.map(Self.csvEscape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    /// Writes the CSV to a temp file and returns its URL, for sharing as a `.csv` attachment.
    func writeCSVFile() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv().write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    var fileName: String {
        let scalars = title.replacingOccurrences(of: " — ", with: "-")
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" }
        let base = String(String.UnicodeScalarView(scalars))
        return (base.isEmpty ? "stickers" : base) + ".csv"
    }

    // MARK: - Helpers

    /// Groups items by section, preserving the order they appear in `items`.
    private func groupedBySection() -> [(section: String, items: [Item])] {
        var order: [String] = []
        var map: [String: [Item]] = [:]
        for item in items {
            if map[item.section] == nil { order.append(item.section) }
            map[item.section, default: []].append(item)
        }
        return order.map { (section: $0, items: map[$0] ?? []) }
    }

    private static func csvEscape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
