import Foundation

/// One printed page of the physical album (Brazilian edition). Built from the
/// catalog so the Pages view mirrors where every sticker actually sits.
struct AlbumPage: Identifiable {
    /// One cell in a page row. Widths are in grid units (a plain slot = 1).
    enum Item: Identifiable {
        case slot(Sticker)                                        // standard slot
        case photoSlot(Sticker)                                   // wide team-photo slot (#13)
        case teamHeader(name: String, flag: String?, group: String?)
        case groupBox(letter: String, flags: [String])            // group fixtures box

        var id: String {
            switch self {
            case .slot(let s), .photoSlot(let s): return s.code
            case .teamHeader(let name, _, _):     return "header-\(name)"
            case .groupBox(let letter, _):        return "group-\(letter)"
            }
        }

        var units: Int {
            switch self {
            case .slot, .groupBox:           return 1
            case .photoSlot, .teamHeader:    return 2
            }
        }

        var sticker: Sticker? {
            switch self {
            case .slot(let s), .photoSlot(let s): return s
            case .teamHeader, .groupBox:          return nil
            }
        }
    }

    let id: String            // stable: "BRA-1", "opening", "coca-cola-2"
    let section: String       // section this page belongs to (jump menu, progress)
    let subtitle: String?     // "1 of 2" for spreads
    let teamCode: String?
    let groupLetter: String?
    let flag: String?
    let columns: Int          // grid units per row
    let rows: [[Item]]

    var stickers: [Sticker] { rows.flatMap { $0 }.compactMap(\.sticker) }
}

/// Translates the flat catalog into printed pages. Team spreads follow the
/// physical album:
///   page 1:  [team header][1][2] / [3][4][5][6] / [7][8][9][10]
///   page 2:  [11][12][team photo] / [14][15][16][17] / [group box][18][19][20]
enum AlbumPageBuilder {
    static func pages(from all: [Sticker]) -> [AlbumPage] {
        let sorted = all.sorted { $0.order < $1.order }
        var pages: [AlbumPage] = []

        let opening = sorted.filter { $0.category == .opening }
        if !opening.isEmpty {
            pages.append(AlbumPage(
                id: "opening", section: "Opening", subtitle: nil,
                teamCode: nil, groupLetter: nil, flag: nil,
                columns: 3, rows: chunked(opening, into: 3)))
        }

        // Team spreads in album order; flags per group for the fixtures box.
        var teamOrder: [String] = []
        var byTeam: [String: [Sticker]] = [:]
        var groupFlags: [String: [String]] = [:]
        for s in sorted {
            guard let code = s.teamCode else { continue }
            if byTeam[code] == nil { teamOrder.append(code) }
            byTeam[code, default: []].append(s)
            if s.category == .teamLogo, let g = s.group, let f = s.flag {
                groupFlags[g, default: []].append(f)
            }
        }

        for code in teamOrder {
            let team = (byTeam[code] ?? []).sorted { $0.number < $1.number }
            guard team.count == 20 else { continue }
            let name = team[0].section
            let flag = team[0].flag
            let group = team[0].group
            func s(_ n: Int) -> AlbumPage.Item { .slot(team[n - 1]) }

            pages.append(AlbumPage(
                id: "\(code)-1", section: name, subtitle: "1 of 2",
                teamCode: code, groupLetter: group, flag: flag, columns: 4,
                rows: [
                    [.teamHeader(name: name, flag: flag, group: group), s(1), s(2)],
                    [s(3), s(4), s(5), s(6)],
                    [s(7), s(8), s(9), s(10)],
                ]))
            pages.append(AlbumPage(
                id: "\(code)-2", section: name, subtitle: "2 of 2",
                teamCode: code, groupLetter: group, flag: flag, columns: 4,
                rows: [
                    [s(11), s(12), .photoSlot(team[12])],
                    [s(14), s(15), s(16), s(17)],
                    [.groupBox(letter: group ?? "", flags: groupFlags[group ?? ""] ?? []),
                     s(18), s(19), s(20)],
                ]))
        }

        let museum = sorted.filter { $0.category == .museum }
        if !museum.isEmpty {
            pages.append(AlbumPage(
                id: "museum", section: "FIFA Museum", subtitle: nil,
                teamCode: nil, groupLetter: nil, flag: nil,
                columns: 4, rows: chunked(museum, into: 4)))
        }

        // Coca-Cola promo spread (album pages 112-113).
        let coke = sorted.filter { $0.category == .special }
        if !coke.isEmpty {
            let half = (coke.count + 1) / 2
            let sides = [Array(coke.prefix(half)), Array(coke.dropFirst(half))]
            for (i, side) in sides.enumerated() where !side.isEmpty {
                pages.append(AlbumPage(
                    id: "coca-cola-\(i + 1)", section: "Coca-Cola",
                    subtitle: sides[1].isEmpty ? nil : "\(i + 1) of 2",
                    teamCode: nil, groupLetter: nil, flag: nil,
                    columns: 4, rows: chunked(side, into: 4)))
            }
        }

        return pages
    }

    private static func chunked(_ stickers: [Sticker], into columns: Int) -> [[AlbumPage.Item]] {
        stride(from: 0, to: stickers.count, by: columns).map { i in
            stickers[i..<min(i + columns, stickers.count)].map { AlbumPage.Item.slot($0) }
        }
    }
}
