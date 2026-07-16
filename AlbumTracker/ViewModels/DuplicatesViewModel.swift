import Foundation

@MainActor @Observable
final class DuplicatesViewModel {
    var allStickers: [Sticker] = []
    var searchText = ""
    var includeSpecials = true
    var isLoading = false
    private(set) var scope: AlbumScope = .physical

    private let repository = StickerRepository.shared
    private var byCode: [String: Sticker] = [:]
    private var loadedScope: AlbumScope?

    struct DuplicateItem: Identifiable {
        let sticker: Sticker
        let count: Int
        let nameOverride: String?
        var id: String { sticker.code }
        var extras: Int { count - 1 }
    }

    struct SectionGroup: Identifiable {
        let id: String
        var name: String { id }
        let flag: String?
        let items: [DuplicateItem]
    }

    func load(scope: AlbumScope = .physical) async {
        guard loadedScope != scope else { return }
        isLoading = allStickers.isEmpty
        self.scope = scope
        allStickers = await repository.loadAll(album: scope.albumId)
        byCode = Dictionary(allStickers.map { ($0.code, $0) }, uniquingKeysWith: { a, _ in a })
        loadedScope = scope
        isLoading = false
    }

    /// Full catalog honoring the Coca-Cola toggle — for the "add duplicate" picker.
    var scopedStickers: [Sticker] {
        includeSpecials ? allStickers : allStickers.filter { $0.category != .special }
    }

    /// Owned-more-than-once stickers, honoring the Coca-Cola toggle and search.
    /// `entryMap` is the current scope's entries keyed by bare sticker code
    /// (see `AlbumScope.entriesByCode`).
    func items(entryMap: [String: StickerCollectionEntry]) -> [DuplicateItem] {
        var result: [DuplicateItem] = []
        for (code, e) in entryMap where e.count >= 2 {
            guard let s = byCode[code] else { continue }
            if !includeSpecials && s.category == .special { continue }
            result.append(DuplicateItem(sticker: s, count: e.count, nameOverride: e.nameOverride))
        }

        let q = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            result = result.filter {
                $0.sticker.code.lowercased().contains(q)
                    || ($0.sticker.name?.lowercased().contains(q) ?? false)
                    || $0.sticker.section.lowercased().contains(q)
            }
        }

        return result.sorted { $0.sticker.order < $1.sticker.order }
    }

    func groups(entryMap: [String: StickerCollectionEntry]) -> [SectionGroup] {
        let all = items(entryMap: entryMap)
        var order: [String] = []
        var map: [String: [DuplicateItem]] = [:]
        for it in all {
            let section = it.sticker.section
            if map[section] == nil { order.append(section) }
            map[section, default: []].append(it)
        }
        return order.map { name in
            let group = map[name] ?? []
            let first = group.first?.sticker
            let isTeam = first?.teamCode != nil
                && first?.category != .update && first?.category != .extra
            return SectionGroup(id: name, flag: isTeam ? first?.flag : nil, items: group)
        }
    }

    func totalExtras(entryMap: [String: StickerCollectionEntry]) -> Int {
        items(entryMap: entryMap).reduce(0) { $0 + $1.extras }
    }

    func distinctCount(entryMap: [String: StickerCollectionEntry]) -> Int {
        items(entryMap: entryMap).count
    }
}
