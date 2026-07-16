import SwiftUI

/// A sticker slot as printed on an album page: a blank cut-out while missing,
/// filled with the section's flag colors (gold foil for Brilliants) once
/// collected — with the player name captioned underneath, like the real page.
struct PageStickerSlot: View {
    let sticker: Sticker
    let count: Int
    let style: AppTheme.FlagStyle
    var nameOverride: String?
    var slotHeight: CGFloat = 104
    let onToggle: () -> Void
    let onAdjust: (Int) -> Void
    /// Long press opens the copies editor sheet (owned by the pages view).
    var onLongPress: () -> Void = {}

    private var owned: Bool { count >= 1 }
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
    }

    var body: some View {
        VStack(spacing: 4) {
            slotFace
                .frame(height: slotHeight)
            Text(sticker.displayTitle(override: nameOverride))
                .font(.system(size: 9, weight: .semibold))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 24, alignment: .top)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        // A context menu here freezes: its preview snapshot fights the paging
        // scroll view's 3D scrollTransition. Long press opens a plain sheet
        // with large +/- controls instead.
        .onLongPressGesture(minimumDuration: 0.35) { onLongPress() }
        .accessibilityAction(named: Text("Add copy")) { onAdjust(1) }
        .accessibilityAction(named: Text("Remove copy")) { onAdjust(-1) }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: count)
        .animation(.snappy(duration: 0.25), value: count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Double tap to toggle collected")
        .accessibilityAddTraits(.isButton)
    }

    private var slotFace: some View {
        ZStack {
            if owned {
                shape.fill(sticker.isFoil
                           ? AnyShapeStyle(AppTheme.foilGradient)
                           : AnyShapeStyle(style.bg))
                if sticker.isFoil {
                    shape.fill(LinearGradient(
                        colors: [.white.opacity(0.35), .clear, .white.opacity(0.12)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                shape.strokeBorder(style.fg.opacity(0.25), lineWidth: 1)
            } else {
                shape.fill(Color.primary.opacity(0.035))
                shape.strokeBorder(
                    sticker.isFoil ? AppTheme.foilDark.opacity(0.55) : style.accent.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }

            VStack(spacing: 2) {
                if let team = sticker.teamCode {
                    Text(team)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1)
                } else {
                    Text(codePrefix)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1)
                }
                Text(slotNumber)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(owned
                             ? (sticker.isFoil ? AppTheme.foilText : style.fg)
                             : Color.secondary.opacity(0.85))

            if owned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(sticker.isFoil ? AppTheme.foilText : style.fg.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .bottomTrailing)
                    .padding(5)
            }

            if count >= 2 {
                Text("×\(count)")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.spare, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .topTrailing)
                    .padding(4)
            }
        }
    }

    private var slotNumber: String {
        sticker.code == "00" ? "00" : "\(sticker.number)"
    }

    /// Non-team stickers: show their series prefix ("FWC", "CC") above the number.
    private var codePrefix: String {
        String(sticker.code.prefix { !$0.isNumber })
    }

    private var accessibilitySummary: String {
        var parts = [sticker.code, sticker.displayTitle(override: nameOverride)]
        if sticker.isFoil { parts.append(String(localized: "Brilliant")) }
        parts.append(owned
                     ? (count >= 2 ? String(localized: "collected, \(count) copies")
                                   : String(localized: "collected"))
                     : String(localized: "missing"))
        return parts.joined(separator: ", ")
    }
}
