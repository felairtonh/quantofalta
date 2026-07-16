import Foundation

@MainActor @Observable
final class AlbumViewModel {
    var allStickers: [Sticker] = []
    var searchText = ""
    var statusFilter: StatusFilter = .all
    var typeFilter: TypeFilter = .all
    var teamFilter: String?            // teamCode, nil = all teams
    var sortMode: SortMode = .album
    var sortAscending = true
    var includeSpecials = true         // Coca-Cola section (driven by Settings)
    var isLoading = false
    private(set) var scope: AlbumScope = .physical

    private let repository = StickerRepository.shared
    private var loadedScope: AlbumScope?

    enum StatusFilter: String, CaseIterable {
        case all = "All", owned = "Have", missing = "Missing"
    }

    enum TypeFilter: String, CaseIterable {
        case all = "All", brilliant = "Brilliant", common = "Players"
    }

    enum SortMode: String, CaseIterable {
        case album = "Album"          // FIFA group-draw order
        case alphabetical = "A–Z"
    }

    struct SectionGroup: Identifiable {
        let id: String          // section name
        var name: String { id }
        let flag: String?       // only set for team sections
        let groupLetter: String? // World Cup group, for team sections
        let stickers: [Sticker]
    }

    func load(scope: AlbumScope = .physical) async {
        guard loadedScope != scope else { return }
        isLoading = allStickers.isEmpty
        self.scope = scope
        allStickers = await repository.loadAll(album: scope.albumId)
        loadedScope = scope
        isLoading = false
    }

    /// Catalog in scope, honoring the Coca-Cola toggle.
    private func scoped() -> [Sticker] {
        includeSpecials ? allStickers : allStickers.filter { $0.category != .special }
    }

    /// Same scoped catalog, exposed for the Pages view.
    var catalogInScope: [Sticker] { scoped() }

    /// Distinct teams for the team picker, in catalog order.
    var teams: [(code: String, name: String, flag: String?)] {
        var seen = Set<String>()
        var out: [(String, String, String?)] = []
        for s in allStickers {
            guard let code = s.teamCode, seen.insert(code).inserted else { continue }
            out.append((code, s.section, s.flag))
        }
        return out.map { (code: $0.0, name: $0.1, flag: $0.2) }
    }

    /// All section names in catalog order (for collapse/expand-all).
    var allSectionNames: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for s in allStickers where seen.insert(s.section).inserted { out.append(s.section) }
        return out
    }

    var hasActiveFilters: Bool {
        statusFilter != .all || typeFilter != .all || teamFilter != nil
    }

    // MARK: - Filtering

    func filtered(counts: [String: Int]) -> [Sticker] {
        var result = scoped()

        if let teamFilter {
            result = result.filter { $0.teamCode == teamFilter }
        }

        switch typeFilter {
        case .all:       break
        case .brilliant: result = result.filter { $0.kind == .brilliant }
        case .common:    result = result.filter { $0.kind == .common }
        }

        switch statusFilter {
        case .all:     break
        case .owned:   result = result.filter { (counts[$0.code] ?? 0) >= 1 }
        case .missing: result = result.filter { (counts[$0.code] ?? 0) == 0 }
        }

        let q = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            result = result.filter {
                $0.code.lowercased().contains(q)
                    || ($0.name?.lowercased().contains(q) ?? false)
                    || $0.section.lowercased().contains(q)
            }
        }

        return result.sorted { $0.order < $1.order }
    }

    func groups(counts: [String: Int]) -> [SectionGroup] {
        var bySection: [String: [Sticker]] = [:]
        for s in filtered(counts: counts) {
            bySection[s.section, default: []].append(s)
        }

        // Album rank = a section's earliest global order (group-draw order).
        func albumRank(_ section: String) -> Int {
            bySection[section]?.map(\.order).min() ?? .max
        }

        var sections = Array(bySection.keys)
        switch sortMode {
        case .album:
            sections.sort { albumRank($0) < albumRank($1) }
        case .alphabetical:
            sections.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
        if !sortAscending { sections.reverse() }

        return sections.map { name in
            // Sort by global order, not number: Update Edition repeats numbers
            // per team (U1/U2) — number sort would clump all the 1s together.
            let stickers = (bySection[name] ?? []).sorted { $0.order < $1.order }
            // Update/fan rows carry team codes but their section isn't a
            // team — don't crown it with the first team's flag.
            let firstCategory = stickers.first?.category
            let isTeam = stickers.first?.teamCode != nil
                && firstCategory != .update && firstCategory != .extra
            return SectionGroup(
                id: name,
                flag: isTeam ? stickers.first?.flag : nil,
                groupLetter: isTeam ? stickers.first?.group : nil,
                stickers: stickers
            )
        }
    }

    /// All stickers currently missing (count 0), honoring the active team filter — for export.
    func missingStickers(counts: [String: Int]) -> [Sticker] {
        var result = scoped().filter { (counts[$0.code] ?? 0) == 0 }
        if let teamFilter { result = result.filter { $0.teamCode == teamFilter } }
        return result.sorted { $0.order < $1.order }
    }

    // MARK: - Progress

    func overallProgress(counts: [String: Int]) -> (owned: Int, total: Int) {
        progress(for: scoped(), counts: counts)
    }

    func brilliantProgress(counts: [String: Int]) -> (owned: Int, total: Int) {
        progress(for: scoped().filter(\.isFoil), counts: counts)
    }

    /// Progress for every section in one catalog pass. (Filtering the catalog
    /// per section made expanded lists cost O(sections × catalog) per render.)
    func sectionProgressAll(counts: [String: Int]) -> [String: (owned: Int, total: Int)] {
        var result: [String: (owned: Int, total: Int)] = [:]
        for s in scoped() {
            var p = result[s.section] ?? (0, 0)
            p.total += 1
            if (counts[s.code] ?? 0) >= 1 { p.owned += 1 }
            result[s.section] = p
        }
        return result
    }

    private func progress(for stickers: [Sticker], counts: [String: Int]) -> (owned: Int, total: Int) {
        let owned = stickers.reduce(0) { $0 + ((counts[$1.code] ?? 0) >= 1 ? 1 : 0) }
        return (owned, stickers.count)
    }
}
