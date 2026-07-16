import Foundation

/// Owns the bundled sticker catalogs (one per album). Loads + caches off the
/// main thread; the decoded arrays are immutable reference data shared by
/// every view model.
actor StickerRepository {
    static let shared = StickerRepository()

    private var cache: [String: [Sticker]] = [:]

    func loadAll(album albumId: String = AlbumScope.physical.albumId) async -> [Sticker] {
        if let cached = cache[albumId] { return cached }
        let result = await BundledDataLoader(albumId: albumId).loadStickers()
        cache[albumId] = result
        return result
    }
}
