import Foundation
import SwiftData

/// User-owned state for one sticker. The single `count` field powers both pages:
/// `0` = missing, `1` = owned, `>= 2` = owned + (count - 1) duplicates.
/// A record is created lazily the first time a sticker's count goes above zero.
@Model
final class StickerCollectionEntry {
    @Attribute(.unique) var stickerCode: String
    var count: Int
    var nameOverride: String?   // in-app correction of a wrong/blank player name
    var note: String?           // free text, e.g. "promised to João"
    var updatedAt: Date?

    init(stickerCode: String, count: Int = 0) {
        self.stickerCode = stickerCode
        self.count = count
    }

    var owned: Bool { count >= 1 }
    var extras: Int { max(0, count - 1) }
}
