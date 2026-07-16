import XCTest
@testable import AlbumTracker

final class ExportTests: XCTestCase {

    private func item(_ code: String, _ number: Int, _ name: String, _ section: String,
                      foil: Bool = false, qty: Int = 1) -> StickerExportList.Item {
        .init(code: code, number: number, name: name, team: section,
              section: section, isFoil: foil, quantity: qty)
    }

    func testMissingTextAndCSV() {
        let list = StickerExportList(
            title: "WC26 Album — Missing",
            items: [
                item("ARG2", 2, "Player", "Argentina"),
                item("ARG7", 7, "Player", "Argentina"),
                item("BRA1", 1, "Team Logo", "Brazil", foil: true),
            ],
            showQuantityInText: false
        )

        let text = list.plainText()
        XCTAssertTrue(text.hasPrefix("WC26 Album — Missing (3)"))
        XCTAssertTrue(text.contains("Argentina: ARG2, ARG7"))
        XCTAssertTrue(text.contains("Brazil: BRA1"))
        XCTAssertFalse(text.contains("×"), "missing list shows no quantity")

        let csv = list.csv()
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.first, "Code,Number,Name,Team,Section,Type,Quantity")
        XCTAssertEqual(lines.count, 4)   // header + 3 rows
        XCTAssertTrue(csv.contains("BRA1,1,Team Logo,Brazil,Brazil,Brilliant,1"))
    }

    func testDuplicatesTextSumsSpares() {
        let list = StickerExportList(
            title: "WC26 Album — Duplicates",
            items: [
                item("ARG3", 3, "Player", "Argentina", qty: 2),
                item("ARG10", 10, "Player", "Argentina", qty: 3),
            ],
            showQuantityInText: true
        )
        let text = list.plainText()
        XCTAssertTrue(text.hasPrefix("WC26 Album — Duplicates (5 spare)"))  // 2 + 3
        XCTAssertTrue(text.contains("Argentina: ARG3 ×2, ARG10 ×3"))
    }

    func testCSVEscapesCommaInName() {
        let list = StickerExportList(
            title: "T",
            items: [item("X1", 1, "Last, First", "Spain")],
            showQuantityInText: false
        )
        XCTAssertTrue(list.csv().contains("\"Last, First\""))
    }

    func testFileNameIsSanitized() {
        let list = StickerExportList(title: "WC26 Album — Missing", items: [], showQuantityInText: false)
        XCTAssertEqual(list.fileName, "WC26-Album-Missing.csv")
    }
}
