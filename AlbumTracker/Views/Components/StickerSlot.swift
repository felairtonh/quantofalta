import SwiftUI

/// The leading "album slot" for a sticker row, styled like the printed album:
/// a dashed empty frame while missing, filled with the section's flag colors once
/// collected. Brilliant (foil) stickers get a gold foil treatment in both states.
struct StickerSlot: View {
    let sticker: Sticker
    let owned: Bool
    let style: AppTheme.FlagStyle
    /// Show the emoji flag instead of the slot number (for mixed, cross-section lists).
    var showsFlag = false

    private var slotNumber: String {
        sticker.code == "00" ? "00" : "\(sticker.number)"
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    var body: some View {
        ZStack {
            if owned {
                shape.fill(sticker.isFoil
                           ? AnyShapeStyle(AppTheme.foilGradient)
                           : AnyShapeStyle(style.bg))
                if sticker.isFoil {
                    // Faint diagonal sheen so foils read as shiny, not just yellow.
                    shape.fill(LinearGradient(
                        colors: [.white.opacity(0.35), .clear, .white.opacity(0.12)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                shape.strokeBorder(style.fg.opacity(0.25), lineWidth: 1)
            } else {
                shape.fill(Color.secondary.opacity(0.06))
                shape.strokeBorder(
                    sticker.isFoil ? AppTheme.foilDark.opacity(0.55) : style.accent.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }

            if showsFlag, let flag = sticker.flag, !flag.isEmpty {
                Text(flag)
                    .font(.title3)
                    .opacity(owned ? 1 : 0.55)
            } else {
                Text(slotNumber)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(owned
                                     ? (sticker.isFoil ? AppTheme.foilText : style.fg)
                                     : Color.secondary)
            }
        }
        .frame(width: 36, height: 44)
        .accessibilityHidden(true)
    }
}
