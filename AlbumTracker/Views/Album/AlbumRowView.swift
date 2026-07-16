import SwiftUI

/// One sticker row on the Album page: an album-style slot (dashed = missing,
/// flag-filled = collected, gold = Brilliant), code + name, and a collected
/// indicator. Rows sit on a neutral cell with a faint section-color wash.
/// Tap to collect/uncollect; swipe to add/remove a copy.
struct AlbumRowView: View {
    let sticker: Sticker
    let count: Int
    let style: AppTheme.FlagStyle
    let onToggleOwned: () -> Void

    private var owned: Bool { count >= 1 }

    var body: some View {
        HStack(spacing: 12) {
            StickerSlot(sticker: sticker, owned: owned, style: style)

            HStack(spacing: 7) {
                // The slot already shows the bare number; skip the code when identical ("00").
                if sticker.code != "00" {
                    Text(sticker.code)
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(sticker.displayTitle())
                    .font(.subheadline.weight(owned ? .semibold : .regular))
                    .foregroundStyle(owned ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            trailing
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleOwned)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: count)
        .animation(.snappy(duration: 0.25), value: count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Double tap to toggle collected")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var trailing: some View {
        if count >= 2 {
            Text("×\(count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.spare, in: Capsule())
                .contentTransition(.numericText())
        } else if owned {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.pitch)
        } else {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(.quaternary)
        }
    }

    private var accessibilitySummary: String {
        var parts = [sticker.code, sticker.displayTitle()]
        if sticker.isFoil { parts.append(String(localized: "Brilliant")) }
        parts.append(owned
                     ? (count >= 2 ? String(localized: "collected, \(count) copies")
                                   : String(localized: "collected"))
                     : String(localized: "missing"))
        return parts.joined(separator: ", ")
    }
}
