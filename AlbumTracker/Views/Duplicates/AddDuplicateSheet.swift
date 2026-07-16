import SwiftUI
import SwiftData

/// Search the whole album and add copies of any sticker. Once a sticker reaches
/// 2+ it shows on the Duplicates list as a spare.
struct AddDuplicateSheet: View {
    let stickers: [Sticker]
    var scope: AlbumScope = .physical
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [StickerCollectionEntry]
    @State private var searchText = ""

    private var byCode: [String: StickerCollectionEntry] {
        scope.entriesByCode(entries)
    }

    private var results: [Sticker] {
        let q = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return stickers }
        return stickers.filter {
            $0.code.lowercased().contains(q)
                || ($0.name?.lowercased().contains(q) ?? false)
                || $0.section.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { sticker in
                row(sticker)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search name or number")
            .navigationTitle("Add Duplicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if results.isEmpty { ContentUnavailableView.search }
            }
        }
        .presentationDetents([.large])
    }

    private func row(_ sticker: Sticker) -> some View {
        let entry = byCode[sticker.code]
        let count = entry?.count ?? 0
        return HStack(spacing: 12) {
            StickerSlot(
                sticker: sticker,
                owned: count >= 1,
                style: AppTheme.sectionStyle(name: sticker.section, teamCode: sticker.teamCode),
                showsFlag: true
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(sticker.code)
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(sticker.displayTitle(override: entry?.nameOverride))
                        .font(.subheadline).fontWeight(.medium).lineLimit(1)
                }
                if count >= 2 {
                    Text("\(count - 1) spare")
                        .font(.caption2.weight(.bold)).foregroundStyle(AppTheme.spare)
                } else if count == 1 {
                    Label("Owned", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.medium)).foregroundStyle(AppTheme.pitch)
                } else {
                    Text(LocalizedStringKey(sticker.section)).font(.caption2).foregroundStyle(.secondary)
                }
            }

            Spacer()

            CopiesStepper(
                count: count,
                onDecrement: { adjust(sticker.code, by: -1) },
                onIncrement: { adjust(sticker.code, by: 1) }
            )
        }
        .padding(.vertical, 2)
    }

    private func adjust(_ code: String, by delta: Int) {
        let key = scope.storageKey(code)
        withAnimation(.snappy(duration: 0.25)) {
            if let existing = entries.first(where: { $0.stickerCode == key }) {
                existing.count = max(0, existing.count + delta)
                existing.updatedAt = Date()
            } else if delta > 0 {
                let new = StickerCollectionEntry(stickerCode: key, count: delta)
                new.updatedAt = Date()
                modelContext.insert(new)
            }
            try? modelContext.save()
        }
    }
}
