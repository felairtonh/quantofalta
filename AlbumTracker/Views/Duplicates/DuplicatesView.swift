import SwiftUI
import SwiftData
import TipKit

struct DuplicatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [StickerCollectionEntry]
    @State private var viewModel = DuplicatesViewModel()
    @State private var showingAdd = false
    @AppStorage("includeCocaCola") private var includeCocaCola = true
    @AppStorage("albumScope") private var albumScopeRaw = AlbumScope.physical.rawValue

    private var scope: AlbumScope { AlbumScope(rawValue: albumScopeRaw) ?? .physical }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Album", selection: $albumScopeRaw) {
                ForEach(AlbumScope.allCases) { s in
                    Text(s.displayName).tag(s.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Group {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading…")
                    Spacer()
                } else {
                    content
                }
            }
        }
        .navigationTitle("Duplicates")
        .searchable(text: $viewModel.searchText, prompt: "Search name or number")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingAdd = true
                } label: {
                    Label("Add Duplicate", systemImage: "plus")
                }
                .popoverTip(AppTips.AddDuplicate())
            }
            ToolbarItem(placement: .topBarTrailing) {
                ExportMenu(makeList: { duplicatesExportList })
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddDuplicateSheet(stickers: viewModel.scopedStickers, scope: scope)
        }
        .task(id: albumScopeRaw) {
            viewModel.includeSpecials = includeCocaCola
            await viewModel.load(scope: scope)
            #if DEBUG
            if ProcessInfo.processInfo.environment["SHOW_ADD"] != nil { showingAdd = true }
            #endif
        }
        .onChange(of: includeCocaCola) { viewModel.includeSpecials = includeCocaCola }
    }

    private var content: some View {
        let entryMap = scope.entriesByCode(entries)
        let groups = viewModel.groups(entryMap: entryMap)
        let totalExtras = viewModel.totalExtras(entryMap: entryMap)
        let distinct = viewModel.distinctCount(entryMap: entryMap)

        return List {
            if !groups.isEmpty {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(totalExtras) spare")
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            (distinct == 1
                             ? Text("across 1 sticker — your trade list")
                             : Text("across \(distinct) stickers — your trade list"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .background {
                        ZStack(alignment: .topTrailing) {
                            AppTheme.spareGradient
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 110))
                                .foregroundStyle(.white.opacity(0.08))
                                .rotationEffect(.degrees(-12))
                                .offset(x: 30, y: -14)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: AppTheme.spareDark.opacity(0.25), radius: 8, y: 4)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(totalExtras) spare stickers across \(distinct) distinct stickers")
                }
            }

            ForEach(groups) { group in
                Section {
                    ForEach(group.items) { item in
                        DuplicateRow(
                            item: item,
                            onIncrement: { adjust(item.sticker.code, by: 1) },
                            onDecrement: { adjust(item.sticker.code, by: -1) }
                        )
                        .listRowBackground(
                            StickerRowBackground(
                                tint: AppTheme.sectionTint(name: item.sticker.section,
                                                           teamCode: item.sticker.teamCode),
                                owned: true
                            )
                        )
                    }
                } header: {
                    HStack(spacing: 8) {
                        if let flag = group.flag { Text(flag) }
                        Text(LocalizedStringKey(group.name)).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(group.items.reduce(0) { $0 + $1.extras }) spare")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .textCase(nil)
                }
            }
        }
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty ? "No duplicates yet" : "No matches",
                    systemImage: "rectangle.stack.badge.plus",
                    description: Text(viewModel.searchText.isEmpty
                        ? "Tap + to add a sticker you have spares of. Anything you own more than once shows up here."
                        : "Try a different search.")
                )
            }
        }
    }

    private func adjust(_ code: String, by delta: Int) {
        let key = scope.storageKey(code)
        guard let existing = entries.first(where: { $0.stickerCode == key }) else { return }
        withAnimation(.snappy(duration: 0.25)) {
            existing.count = max(0, existing.count + delta)
            existing.updatedAt = Date()
            try? modelContext.save()
        }
    }

    /// The duplicates list for export (quantity = spares).
    private var duplicatesExportList: StickerExportList {
        let items = viewModel.items(entryMap: scope.entriesByCode(entries)).map { item in
            StickerExportList.Item(
                code: item.sticker.code,
                number: item.sticker.number,
                name: item.sticker.displayTitle(override: item.nameOverride),
                team: item.sticker.teamCode != nil ? item.sticker.section : "",
                section: item.sticker.section,
                isFoil: item.sticker.isFoil,
                quantity: item.extras
            )
        }
        return StickerExportList(title: "\(scope.exportTitle) — Duplicates", items: items, showQuantityInText: true)
    }
}

private struct DuplicateRow: View {
    let item: DuplicatesViewModel.DuplicateItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    private var sticker: Sticker { item.sticker }

    var body: some View {
        HStack(spacing: 12) {
            StickerSlot(
                sticker: sticker,
                owned: true,
                style: AppTheme.sectionStyle(name: sticker.section, teamCode: sticker.teamCode),
                showsFlag: true
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(sticker.code)
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(sticker.displayTitle(override: item.nameOverride))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Text("\(item.extras) spare")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.spare, in: Capsule())
                    .contentTransition(.numericText())
            }

            Spacer()

            CopiesStepper(count: item.count, onDecrement: onDecrement, onIncrement: onIncrement)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
