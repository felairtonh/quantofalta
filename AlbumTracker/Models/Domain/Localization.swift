import Foundation

extension String {
    /// Catalog-localized rendering of a data-driven string. Team and section
    /// names live in the bundled JSON in English (they are stable identifiers
    /// for storage and search); the string catalog carries their pt-BR
    /// display names. Falls back to the string itself.
    var localizedName: String {
        NSLocalizedString(self, comment: "data-driven name")
    }
}
