import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [StickerCollectionEntry]
    @AppStorage("includeCocaCola") private var includeCocaCola = true
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var allStickers: [Sticker] = []
    @State private var digitalStickers: [Sticker] = []
    @State private var showingResetConfirm = false

    /// All per-entry aggregation in one pass. Computed once per body
    /// evaluation — the previous computed vars rebuilt their dictionaries on
    /// every single access, several times per render.
    private struct Stats {
        var counts: [String: Int] = [:]
        var digitalCounts: [String: Int] = [:]
        var spares = 0
        var digitalSpares = 0
    }

    private func makeStats() -> Stats {
        var s = Stats()
        for e in entries {
            if AlbumScope.digital.owns(e) {
                s.digitalCounts[AlbumScope.digital.code(of: e)] = e.count
                s.digitalSpares += max(0, e.count - 1)
            } else {
                s.counts[e.stickerCode] = e.count
                s.spares += max(0, e.count - 1)
            }
        }
        return s
    }

    private var scoped: [Sticker] {
        includeCocaCola ? allStickers : allStickers.filter { $0.category != .special }
    }
    private func owned(_ stickers: [Sticker], counts: [String: Int]) -> Int {
        stickers.reduce(0) { $0 + ((counts[$1.code] ?? 0) >= 1 ? 1 : 0) }
    }

    var body: some View {
        let stats = makeStats()
        let scopedStickers = scoped
        let foils = scopedStickers.filter(\.isFoil)
        let specials = scopedStickers.filter { $0.category == .special }
        let ownedCount = owned(scopedStickers, counts: stats.counts)
        let completion = scopedStickers.isEmpty
            ? 0 : Int((Double(ownedCount) / Double(scopedStickers.count) * 100).rounded())

        return Form {
            Section {
                ProgressBarRow(label: "Album", owned: ownedCount, total: scopedStickers.count,
                               tint: AppTheme.pitch)
                ProgressBarRow(label: "Brilliant",
                               owned: owned(foils, counts: stats.counts),
                               total: foils.count,
                               tint: AppTheme.foilDark)
                if includeCocaCola {
                    ProgressBarRow(label: "Coca-Cola",
                                   owned: owned(specials, counts: stats.counts),
                                   total: specials.count,
                                   tint: AppTheme.cocaCola)
                }
                LabeledContent("Completion", value: "\(completion)%")
                LabeledContent("Spare stickers", value: "\(stats.spares)")
            } header: {
                Text("Physical Album")
            }

            Section {
                ProgressBarRow(label: "Collection",
                               owned: owned(digitalStickers, counts: stats.digitalCounts),
                               total: digitalStickers.count,
                               tint: AppTheme.digital)
                LabeledContent("Spare stickers", value: "\(stats.digitalSpares)")
            } header: {
                Text("Digital Album (FIFA Panini Collection)")
            } footer: {
                Text("Tracked separately — switch albums at the top of the Album and Duplicates tabs.")
            }

            Section {
                Toggle("Include Coca-Cola set", isOn: $includeCocaCola)
            } header: {
                Text("Sets")
            } footer: {
                Text("The 14 Coca-Cola stickers (CC1–CC14) come from under promo bottle labels and have their own album spread. Turn off to drop them from lists and progress.")
            }

            Section {
                Button {
                    hasSeenWelcome = false
                } label: {
                    Label("Show welcome tour", systemImage: "sparkles")
                }
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            } header: {
                Text("Help")
            }

            Section {
                Button(role: .destructive) {
                    showingResetConfirm = true
                } label: {
                    Label("Reset all progress", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("Album", value: "Panini FIFA World Cup 2026")
                LabeledContent("Stickers",
                               value: String(localized: "\(allStickers.count) + \(digitalStickers.count) digital"))
                LabeledContent("Version", value: Bundle.main.object(
                    forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                Text("Player names come from public checklists and are best-effort — they can be edited for roster changes or typos. You can always track by sticker number; that's how the album fills.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task {
            if allStickers.isEmpty {
                allStickers = await StickerRepository.shared.loadAll()
            }
            if digitalStickers.isEmpty {
                digitalStickers = await StickerRepository.shared.loadAll(album: AlbumScope.digital.albumId)
            }
        }
        .confirmationDialog("Reset all progress?",
                            isPresented: $showingResetConfirm,
                            titleVisibility: .visible) {
            Button("Reset everything", role: .destructive, action: resetAll)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently clears every owned sticker and duplicate in BOTH the physical and digital albums. It can't be undone.")
        }
    }

    private func resetAll() {
        for entry in entries { modelContext.delete(entry) }
        try? modelContext.save()
    }
}
