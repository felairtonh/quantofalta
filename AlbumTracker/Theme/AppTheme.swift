import SwiftUI

extension Color {
    /// Hex like "0E8A4A".
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// "Matchday" palette — pitch green + gold foil, with a distinct color per World Cup group.
enum AppTheme {
    static let pitch = Color(hex: "0E8A4A")
    static let pitchDark = Color(hex: "0A6B3A")
    static let foilLight = Color(hex: "F7D774")
    static let foilDark = Color(hex: "D99A2B")
    static let foilText = Color(hex: "6B4E00")
    static let spare = Color(hex: "E8821E")
    static let spareDark = Color(hex: "CC6A12")

    static var pitchGradient: LinearGradient {
        LinearGradient(colors: [pitch, pitchDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var foilGradient: LinearGradient {
        LinearGradient(colors: [foilLight, foilDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var spareGradient: LinearGradient {
        LinearGradient(colors: [spare, spareDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// One readable, white-text-friendly color per group A–L.
    private static let groupPalette: [Color] = [
        Color(hex: "D64550"), Color(hex: "E07A1F"), Color(hex: "B98900"),
        Color(hex: "2E8B57"), Color(hex: "1A9E8F"), Color(hex: "2D7DD2"),
        Color(hex: "4150B5"), Color(hex: "7E4DBF"), Color(hex: "C13D8A"),
        Color(hex: "8B6A4F"), Color(hex: "2B8A6B"), Color(hex: "5566C9"),
    ]

    static func group(_ letter: String?) -> Color {
        guard let ascii = letter?.first?.asciiValue, (65...76).contains(ascii) else { return pitch }
        return groupPalette[Int(ascii - 65)]
    }

    static let cocaCola = Color(hex: "E61A27")
    /// Accent for the digital album (FIFA Panini Collection).
    static let digital = Color(hex: "2D7DD2")

    struct FlagStyle {
        let bg: Color
        let fg: Color
        /// The section's color for use on neutral (system) backgrounds — the flag's
        /// bg, unless that is near-white (England, Japan), then the fg. Drives row
        /// washes, empty-slot dashes, and anything tinted outside the colored header.
        let accent: Color
    }

    /// Relative luminance of a hex color (0 = black, 1 = white).
    private static func luminance(_ hex: String) -> Double {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Two-tone flag style per nation: (background hex, foreground/text hex). Chosen for
    /// flag authenticity and readable contrast.
    private static let flagStyles: [String: (String, String)] = [
        "ALG": ("006233", "FFFFFF"), "ARG": ("5B8FCB", "FFFFFF"), "AUS": ("00247D", "FFFFFF"),
        "AUT": ("C8102E", "FFFFFF"), "BEL": ("222222", "F3C300"), "BIH": ("0A4EA2", "F4D000"),
        "BRA": ("009C3B", "FFDF00"), "CAN": ("D52B1E", "FFFFFF"), "CPV": ("003893", "FFFFFF"),
        "COL": ("F4C300", "00338D"), "CIV": ("F77F00", "FFFFFF"), "CRO": ("C8102E", "FFFFFF"),
        "CUW": ("002B7F", "F9D616"), "CZE": ("11457E", "FFFFFF"), "COD": ("0089CC", "F7D618"),
        "ECU": ("FFD100", "00338D"), "EGY": ("CE1126", "FFFFFF"), "ENG": ("FFFFFF", "CF142B"),
        "FRA": ("0055A4", "FFFFFF"), "GER": ("222222", "E0B000"), "GHA": ("006B3F", "FCD116"),
        "HAI": ("00209F", "FFFFFF"), "IRN": ("239F40", "FFFFFF"), "IRQ": ("CE1126", "FFFFFF"),
        "JPN": ("FFFFFF", "BC002D"), "JOR": ("007A3D", "FFFFFF"), "KOR": ("0A3A8F", "FFFFFF"),
        "MEX": ("006847", "FFFFFF"), "MAR": ("C1272D", "FFFFFF"), "NED": ("EA6F2D", "FFFFFF"),
        "NZL": ("1A3A6B", "FFFFFF"), "NOR": ("BA0C2F", "FFFFFF"), "PAN": ("005293", "FFFFFF"),
        "PAR": ("D52B1E", "FFFFFF"), "POR": ("006B3F", "FFFFFF"), "QAT": ("8A1538", "FFFFFF"),
        "KSA": ("006C35", "FFFFFF"), "SCO": ("005EB8", "FFFFFF"), "SEN": ("00853F", "FDEF42"),
        "RSA": ("007A4D", "FFB915"), "ESP": ("C60B1E", "FFC400"), "SWE": ("006AA7", "FECC02"),
        "SUI": ("D52B1E", "FFFFFF"), "TUN": ("E70013", "FFFFFF"), "TUR": ("E30A17", "FFFFFF"),
        "USA": ("2A3563", "FFFFFF"), "URU": ("3D6FB8", "FFFFFF"), "UZB": ("0099B5", "FFFFFF"),
    ]

    /// Solid two-tone style for a section. Themed sections come first so the
    /// digital album's cross-team sets (Update Edition etc.) don't inherit the
    /// colors of whichever team happens to appear first; teams then resolve
    /// by flag; everything else falls back to pitch green.
    static func sectionStyle(name: String, teamCode: String?) -> FlagStyle {
        switch name {
        case "Coca-Cola", "#AllTheFeels":
            return FlagStyle(bg: cocaCola, fg: .white, accent: cocaCola)
        case "FIFA Museum", "Trophy Tour":
            let gold = Color(hex: "B8860B")
            return FlagStyle(bg: gold, fg: .white, accent: gold)
        case "Host City Posters":
            let city = Color(hex: "2D7DD2")
            return FlagStyle(bg: city, fg: .white, accent: city)
        case "Update Edition":
            let update = Color(hex: "7E4DBF")
            return FlagStyle(bg: update, fg: .white, accent: update)
        case "Fan Stickers":
            let fan = Color(hex: "C13D8A")
            return FlagStyle(bg: fan, fg: .white, accent: fan)
        case "McDonald's":
            return FlagStyle(bg: Color(hex: "DA291C"), fg: Color(hex: "FFC72C"),
                             accent: Color(hex: "DA291C"))
        default:
            break
        }
        if let teamCode, let pair = flagStyles[teamCode] {
            let accent = luminance(pair.0) > 0.82 ? Color(hex: pair.1) : Color(hex: pair.0)
            return FlagStyle(bg: Color(hex: pair.0), fg: Color(hex: pair.1), accent: accent)
        }
        return FlagStyle(bg: pitch, fg: .white, accent: pitch)   // Opening / Intro + fallback
    }

    /// Tint for a section on neutral backgrounds (row washes on the Album and Duplicates pages).
    static func sectionTint(name: String, teamCode: String?) -> Color {
        sectionStyle(name: name, teamCode: teamCode).accent
    }
}
