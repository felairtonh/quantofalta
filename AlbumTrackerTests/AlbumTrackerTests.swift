import XCTest
@testable import AlbumTracker

final class CatalogTests: XCTestCase {

    // MARK: - Schema (bundle-independent)

    func testStickerDecodingSchema() throws {
        let json = """
        [
          {"code":"MEX1","number":1,"order":20,"name":null,"kind":"brilliant","category":"team_logo","section":"Mexico","team_code":"MEX","flag":"🇲🇽","group":"A"},
          {"code":"MEX5","number":5,"order":24,"name":"César Montes","kind":"common","category":"player","section":"Mexico","team_code":"MEX","flag":"🇲🇽","group":"A"},
          {"code":"CC1","number":1,"order":980,"name":"Lamine Yamal","kind":"common","category":"special","section":"Coca-Cola","team_code":null,"flag":"🇪🇸","group":null}
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let stickers = try decoder.decode([Sticker].self, from: json)

        XCTAssertEqual(stickers.count, 3)

        let logo = stickers[0]
        XCTAssertEqual(logo.teamCode, "MEX")            // team_code -> teamCode
        XCTAssertEqual(logo.category, .teamLogo)        // "team_logo" -> .teamLogo
        XCTAssertEqual(logo.group, "A")
        XCTAssertTrue(logo.isFoil)
        XCTAssertEqual(logo.displayTitle(), "Team Logo") // nil name -> category label
        XCTAssertEqual(stickers[2].group, nil)          // null decodes to nil

        XCTAssertEqual(stickers[1].category, .player)
        XCTAssertFalse(stickers[1].isFoil)

        let cc = stickers[2]
        XCTAssertEqual(cc.category, .special)
        XCTAssertEqual(cc.displayTitle(), "Lamine Yamal")
        XCTAssertEqual(cc.displayTitle(override: "Yamal"), "Yamal")
    }

    // MARK: - Bundled catalog

    func testBundledCatalogCounts() async {
        let stickers = await StickerRepository.shared.loadAll()

        XCTAssertEqual(stickers.count, 994, "catalog should have 994 stickers")
        XCTAssertEqual(stickers.filter(\.isFoil).count, 68, "68 brilliant/foil")
        XCTAssertEqual(stickers.filter { $0.category == .opening }.count, 9)
        XCTAssertEqual(stickers.filter { $0.category == .museum }.count, 11)
        XCTAssertEqual(stickers.filter { $0.category == .teamLogo }.count, 48)
        XCTAssertEqual(stickers.filter { $0.category == .teamPhoto }.count, 48)
        XCTAssertEqual(stickers.filter { $0.category == .player }.count, 864)
        XCTAssertEqual(stickers.filter { $0.category == .special }.count, 14)

        XCTAssertEqual(Set(stickers.compactMap(\.teamCode)).count, 48, "48 distinct teams")
        XCTAssertEqual(Set(stickers.map(\.code)).count, stickers.count, "codes are unique")
        XCTAssertEqual(stickers.filter { $0.teamCode == "MEX" }.count, 20, "20 per team")

        // catalog is pre-sorted by global order (= album / group-draw order)
        XCTAssertEqual(stickers.map(\.order), stickers.map(\.order).sorted())

        // 12 groups, 80 stickers each (4 teams × 20)
        XCTAssertEqual(Set(stickers.compactMap(\.group)).count, 12)
        XCTAssertEqual(stickers.filter { $0.group == "A" }.count, 80)

        // album order: first team after the opening/museum foils is Mexico (Group A1)
        XCTAssertEqual(stickers.first { $0.teamCode != nil }?.code, "MEX1")

        // player names are populated
        XCTAssertEqual(stickers.filter { $0.category == .player && $0.name != nil }.count, 864)
        XCTAssertEqual(stickers.first { $0.code == "ARG17" }?.name, "Lionel Messi")
    }

    // MARK: - Digital album (FIFA Panini Collection)

    func testDigitalCatalogCounts() async {
        let stickers = await StickerRepository.shared.loadAll(album: AlbumScope.digital.albumId)

        XCTAssertEqual(stickers.count, 798, "digital album should have 798 stickers")
        XCTAssertEqual(stickers.filter(\.isFoil).count, 57, "9 intro foils + 48 emblems")
        XCTAssertEqual(stickers.filter { $0.category == .player }.count, 528, "48 × 11 players")
        XCTAssertEqual(stickers.filter { $0.category == .teamLogo }.count, 48)
        XCTAssertEqual(stickers.filter { $0.category == .update }.count, 96, "2 per team")
        XCTAssertEqual(stickers.filter { $0.category == .hostCity }.count, 16)
        XCTAssertEqual(stickers.filter { $0.section == "#AllTheFeels" }.count, 14)
        XCTAssertEqual(stickers.filter { $0.section == "Trophy Tour" }.count, 31)
        XCTAssertEqual(stickers.filter { $0.section == "Fan Stickers" }.count, 48)
        XCTAssertEqual(stickers.filter { $0.section == "McDonald's" }.count, 8)
        XCTAssertEqual(Set(stickers.map(\.code)).count, stickers.count, "codes unique")

        // 12 slots per team (emblem 0 + players 1-11), update/fan stickers aside.
        XCTAssertEqual(stickers.filter {
            $0.teamCode == "BRA" && $0.category != .update && $0.category != .extra
        }.count, 12)
        XCTAssertEqual(stickers.first { $0.code == "BRA0" }?.category, .teamLogo, "emblem is slot 0")

        // Fan stickers follow team draw order and are named after the team.
        let fan1 = stickers.first { $0.code == "FAN1" }
        XCTAssertEqual(fan1?.name, "Mexico")
        XCTAssertEqual(fan1?.teamCode, "MEX")

        // Names filled from the published digital checklist.
        XCTAssertEqual(stickers.first { $0.code == "BRA6" }?.name, "Bruno Guimarães")
        XCTAssertEqual(stickers.first { $0.code == "BRAU1" }?.name, "Neymar Jr")

        // #AllTheFeels mirrors the physical Coca-Cola set.
        XCTAssertEqual(stickers.first { $0.code == "CC1" }?.name, "Lamine Yamal")
        XCTAssertEqual(stickers.first { $0.code == "CC14" }?.name, "Lautaro Martínez")
    }

    func testAlbumScopeStorageKeys() {
        XCTAssertEqual(AlbumScope.physical.storageKey("BRA5"), "BRA5")
        XCTAssertEqual(AlbumScope.digital.storageKey("BRA5"), "d:BRA5")

        let physical = StickerCollectionEntry(stickerCode: "BRA5", count: 2)
        let digital = StickerCollectionEntry(stickerCode: "d:BRA5", count: 1)

        XCTAssertTrue(AlbumScope.physical.owns(physical))
        XCTAssertFalse(AlbumScope.physical.owns(digital))
        XCTAssertTrue(AlbumScope.digital.owns(digital))
        XCTAssertEqual(AlbumScope.digital.code(of: digital), "BRA5")

        // Scoping splits the shared table cleanly by bare code.
        let map = AlbumScope.digital.entriesByCode([physical, digital])
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map["BRA5"]?.count, 1)
        XCTAssertEqual(AlbumScope.physical.entriesByCode([physical, digital])["BRA5"]?.count, 2)
    }

    @MainActor
    func testDigitalUpdateEditionKeepsAlbumOrder() async {
        let vm = AlbumViewModel()
        await vm.load(scope: .digital)

        let update = vm.groups(counts: [:]).first { $0.name == "Update Edition" }
        // Interleaved by team (U1, U2 per team) — a number sort would clump
        // all the U1s together.
        XCTAssertEqual(update.map { Array($0.stickers.prefix(4).map(\.code)) },
                       ["MEXU1", "MEXU2", "RSAU1", "RSAU2"])
        XCTAssertNil(update?.flag, "cross-team sections don't wear one team's flag")
    }

    // MARK: - Album pages

    func testPageBuilderCoversCatalogExactlyOnce() async {
        let stickers = await StickerRepository.shared.loadAll()
        let pages = AlbumPageBuilder.pages(from: stickers)

        let placed = pages.flatMap(\.stickers).map(\.code)
        XCTAssertEqual(placed.count, stickers.count, "every sticker on exactly one page")
        XCTAssertEqual(Set(placed).count, placed.count, "no sticker on two pages")

        // 1 opening + 48 team spreads (2 pages each) + 1 museum + 2 Coca-Cola
        XCTAssertEqual(pages.count, 1 + 96 + 1 + 2)
    }

    func testTeamSpreadMatchesPhysicalLayout() async {
        let stickers = await StickerRepository.shared.loadAll()
        let pages = AlbumPageBuilder.pages(from: stickers)

        guard let p1 = pages.first(where: { $0.id == "BRA-1" }),
              let p2 = pages.first(where: { $0.id == "BRA-2" }) else {
            return XCTFail("missing Brazil spread")
        }

        // Page 1: [header][1][2] / [3][4][5][6] / [7][8][9][10]
        XCTAssertEqual(p1.rows.map(\.count), [3, 4, 4])
        XCTAssertEqual(p1.rows[0].compactMap(\.sticker).map(\.number), [1, 2])
        XCTAssertEqual(p1.rows[1].compactMap(\.sticker).map(\.number), [3, 4, 5, 6])
        XCTAssertEqual(p1.rows[2].compactMap(\.sticker).map(\.number), [7, 8, 9, 10])
        if case .teamHeader = p1.rows[0][0] {} else {
            XCTFail("page 1 should start with the team header block")
        }

        // Page 2: [11][12][photo] / [14][15][16][17] / [group box][18][19][20]
        XCTAssertEqual(p2.rows[0].compactMap(\.sticker).map(\.number), [11, 12, 13])
        XCTAssertEqual(p2.rows[1].compactMap(\.sticker).map(\.number), [14, 15, 16, 17])
        XCTAssertEqual(p2.rows[2].compactMap(\.sticker).map(\.number), [18, 19, 20])
        if case .photoSlot(let photo) = p2.rows[0][2] {
            XCTAssertEqual(photo.category, .teamPhoto)
        } else {
            XCTFail("wide team-photo slot should sit at page 2, row 1, col 3")
        }
        if case .groupBox(let letter, let flags) = p2.rows[2][0] {
            XCTAssertEqual(letter, "C")
            XCTAssertEqual(flags.count, 4)
        } else {
            XCTFail("group box should lead page 2, row 3")
        }
    }

    // MARK: - Sorting

    @MainActor
    func testSortModes() async {
        let vm = AlbumViewModel()
        await vm.load()

        // Album order: opening section comes first.
        XCTAssertEqual(vm.groups(counts: [:]).first?.name, "Opening")

        // Alphabetical: sections sorted case-insensitively A→Z.
        vm.sortMode = .alphabetical
        let asc = vm.groups(counts: [:]).map(\.name)
        XCTAssertEqual(asc, asc.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })

        // Descending reverses the section order.
        vm.sortAscending = false
        XCTAssertEqual(vm.groups(counts: [:]).map(\.name), asc.reversed())
    }
}
