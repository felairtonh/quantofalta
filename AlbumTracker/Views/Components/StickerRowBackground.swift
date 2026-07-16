import SwiftUI

/// A section/flag-colored wash for list rows, layered over the grouped-cell background.
/// Owned cells get a stronger highlight; missing cells stay faint; headers sit in between.
struct StickerRowBackground: View {
    let tint: Color
    /// nil = section header (neutral) · true = owned (highlight) · false = missing (faint)
    var owned: Bool? = nil

    var body: some View {
        let opacity: Double = owned == nil ? 0.13 : (owned == true ? 0.22 : 0.06)
        ZStack {
            Color(.secondarySystemGroupedBackground)
            tint.opacity(opacity)
        }
    }
}
