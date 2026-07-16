import Foundation

/// Which album a view is tracking: the physical Panini album, or the FIFA
/// Panini Collection app (the digital album, where swap requests are made).
///
/// Both share one SwiftData table: digital rows store their sticker code with
/// a `d:` prefix (`d:BRA5`), physical rows stay bare. That keeps codes unique
/// across albums with no schema change, so existing user data is untouched.
enum AlbumScope: String, CaseIterable, Identifiable {
    case physical
    case digital

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .physical: return String(localized: "Physical")
        case .digital:  return String(localized: "Digital")
        }
    }

    /// BundledData folder holding this album's catalog.
    var albumId: String {
        switch self {
        case .physical: return "world-cup-2026"
        case .digital:  return "fifa-panini-collection"
        }
    }

    /// Title prefix for exported lists.
    var exportTitle: String {
        switch self {
        case .physical: return String(localized: "My album")
        case .digital:  return String(localized: "Digital album")
        }
    }

    private static let digitalPrefix = "d:"

    /// The storage key for a sticker code in this scope.
    func storageKey(_ code: String) -> String {
        self == .digital ? Self.digitalPrefix + code : code
    }

    /// Whether a stored entry belongs to this scope.
    func owns(_ entry: StickerCollectionEntry) -> Bool {
        entry.stickerCode.hasPrefix(Self.digitalPrefix) == (self == .digital)
    }

    /// The bare sticker code of an entry in this scope.
    func code(of entry: StickerCollectionEntry) -> String {
        self == .digital
            ? String(entry.stickerCode.dropFirst(Self.digitalPrefix.count))
            : entry.stickerCode
    }

    /// This scope's entries, keyed by bare sticker code.
    func entriesByCode(_ entries: [StickerCollectionEntry]) -> [String: StickerCollectionEntry] {
        Dictionary(entries.compactMap { owns($0) ? (code(of: $0), $0) : nil },
                   uniquingKeysWith: { a, _ in a })
    }
}
