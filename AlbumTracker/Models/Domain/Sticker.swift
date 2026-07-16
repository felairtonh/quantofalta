import Foundation

/// One slot in the Panini World Cup 2026 album. Immutable catalog data decoded
/// from the bundled `stickers.json`. User-owned state lives in `StickerCollectionEntry`.
struct Sticker: Codable, Identifiable, Hashable {
    var id: String { code }
    let code: String        // "00", "FWC1", "MEX1"
    let number: Int         // position within its section (the numeric part of the code)
    let order: Int          // global display order across the whole album
    let name: String?       // player / descriptive name; nil for most slots (track by number)
    let kind: StickerKind   // brilliant (foil) | common  ← the Emblem vs. Player filter
    let category: Category
    let section: String     // group header: "Opening", "FIFA Museum", a team name, "Coca-Cola"
    let teamCode: String?   // FIFA code, e.g. "MEX"
    let flag: String?       // emoji flag, e.g. "🇲🇽"
    let group: String?      // World Cup group letter "A"…"L" (team stickers only)

    /// Foil/"Brilliant" stickers: opening foils, FIFA Museum, and the 48 team logos.
    var isFoil: Bool { kind == .brilliant }

    /// Fallback label used when a sticker has no specific `name`.
    var categoryLabel: String {
        switch category {
        case .opening:   return String(localized: "Opening")
        case .museum:    return String(localized: "FIFA Museum")
        case .teamLogo:  return String(localized: "Team Logo")
        case .teamPhoto: return String(localized: "Team Photo")
        case .player:    return String(localized: "Player")
        case .special:   return "Coca-Cola"
        case .hostCity:  return String(localized: "Host City")
        case .update:    return String(localized: "Update")
        case .extra:     return section.localizedName   // "Fan Stickers", "Trophy Tour"…
        }
    }

    /// Title to show in lists: a user override, else the catalog name, else the category label.
    func displayTitle(override: String? = nil) -> String {
        if let override, !override.isEmpty { return override }
        if let name, !name.isEmpty {
            // Extras are named after teams/countries ("Mexico", "Algeria"…) —
            // localize those through the catalog; player names stay verbatim.
            return category == .extra ? name.localizedName : name
        }
        return categoryLabel
    }
}

enum StickerKind: String, Codable, CaseIterable {
    case brilliant
    case common

    /// Label for the type filter (the user's "Emblems (Brilliant) vs common (players)").
    var displayName: String {
        switch self {
        case .brilliant: return "Brilliant"
        case .common:    return "Players"
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case opening
    case museum
    case teamLogo = "team_logo"
    case teamPhoto = "team_photo"
    case player
    case special                     // Coca-Cola set (physical CC / digital #AllTheFeels)
    // Digital-album (FIFA Panini Collection) sections:
    case hostCity = "host_city"      // host city posters
    case update                      // Update Edition (2 per team)
    case extra                       // Fan Stickers / McDonald's / Trophy Tour
}
