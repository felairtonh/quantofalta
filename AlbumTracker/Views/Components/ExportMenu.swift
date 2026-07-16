import SwiftUI

/// Toolbar share control: offers "Share as Text" (paste-ready) and "Export CSV"
/// (a `.csv` file) via the system share sheet.
///
/// The list is built only when the menu opens: it requires a full catalog scan,
/// and building it eagerly made every body evaluation of the host view pay
/// that cost on every sticker tap.
struct ExportMenu: View {
    let makeList: () -> StickerExportList

    var body: some View {
        Menu {
            let list = makeList()
            if list.items.isEmpty {
                Text("Nothing to share")
            } else {
                ShareLink("Share as Text", item: list.plainText())
                if let csvURL = list.writeCSVFile() {
                    ShareLink("Export CSV", item: csvURL)
                }
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
}
