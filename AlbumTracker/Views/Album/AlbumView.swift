import SwiftUI
import SwiftData
import TipKit

struct AlbumView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [StickerCollectionEntry]
    @State private var viewModel = AlbumViewModel()
    @State private var collapsedSections: Set<String> = []
    @State private var showingFilter = false
    @AppStorage("includeCocaCola") private var includeCocaCola = true
    @AppStorage("albumViewMode") private var albumViewModeRaw = "list"
    @AppStorage("albumScope") private var albumScopeRaw = AlbumScope.physical.rawValue

    private var scope: AlbumScope { AlbumScope(rawValue: albumScopeRaw) ?? .physical }
    /// The Pages view mirrors the physical album's print layout; the digital
    /// album (FIFA Panini Collection) has no confirmed page layout yet.
    private var isPagesMode: Bool { albumViewModeRaw == "pages" && scope == .physical }

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
                } else if isPagesMode {
                    pagesContent
                } else {
                    content
                        .searchable(text: $viewModel.searchText, prompt: "Search name or number")
                }
            }
        }
        .navigationTitle("What's Missing?")
        .navigationBarTitleDisplayMode(isPagesMode ? .inline : .automatic)
        .toolbar {
            if !isPagesMode {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilter = true
                    } label: {
                        Image(systemName: viewModel.hasActiveFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                    .popoverTip(AppTips.Controls())
                }
            }
            if scope == .physical {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { albumViewModeRaw = isPagesMode ? "list" : "pages" }
                    } label: {
                        Image(systemName: isPagesMode ? "list.bullet" : "book.pages")
                    }
                    .accessibilityLabel(isPagesMode ? "Show as list" : "Show as album pages")
                }
            }
            if !isPagesMode {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Expand All", systemImage: "chevron.down") {
                            withAnimation { collapsedSections.removeAll() }
                        }
                        Button("Collapse All", systemImage: "chevron.forward") {
                            withAnimation { collapsedSections = Set(viewModel.allSectionNames) }
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ExportMenu(makeList: { missingExportList })
            }
        }
        .sheet(isPresented: $showingFilter) {
            AlbumFilterSheet(viewModel: viewModel)
        }
        .task(id: albumScopeRaw) {
            viewModel.includeSpecials = includeCocaCola
            await viewModel.load(scope: scope)
            #if DEBUG
            if let team = ProcessInfo.processInfo.environment["START_TEAM"], !team.isEmpty {
                viewModel.teamFilter = team
            }
            if ProcessInfo.processInfo.environment["COLLAPSE_ALL"] != nil {
                collapsedSections = Set(viewModel.allSectionNames)
            }
            if let q = ProcessInfo.processInfo.environment["START_SEARCH"], !q.isEmpty {
                viewModel.searchText = q
            }
            if ProcessInfo.processInfo.environment["SHOW_FILTER"] != nil { showingFilter = true }
            if let mode = ProcessInfo.processInfo.environment["START_VIEW"], !mode.isEmpty {
                albumViewModeRaw = mode
            }
            if ProcessInfo.processInfo.environment["SORT_DESC"] != nil {
                viewModel.sortAscending = false
            }
            #endif
        }
        .onChange(of: includeCocaCola) { viewModel.includeSpecials = includeCocaCola }
    }

    private var content: some View {
        let byCode = entriesByCode
        let counts = byCode.mapValues(\.count)
        let overall = viewModel.overallProgress(counts: counts)
        let groups = viewModel.groups(counts: counts)
        // While searching, show all matches regardless of collapse state.
        let effectiveCollapsed = viewModel.searchText.isEmpty ? collapsedSections : []

        let brilliant = viewModel.brilliantProgress(counts: counts)
        let spares = counts.values.reduce(0) { $0 + max(0, $1 - 1) }
        let sectionProgress = viewModel.sectionProgressAll(counts: counts)

        return List {
            Section {
                ProgressHeaderCard(
                    owned: overall.owned, total: overall.total,
                    brilliantOwned: brilliant.owned, brilliantTotal: brilliant.total,
                    spares: spares
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            }

            ForEach(groups) { group in
                let collapsed = effectiveCollapsed.contains(group.name)
                let style = AppTheme.sectionStyle(name: group.name,
                                                  teamCode: group.stickers.first?.teamCode)
                Section {
                    sectionHeader(group, progress: sectionProgress[group.name] ?? (0, 0),
                                  collapsed: collapsed, style: style)
                        .listRowBackground(style.bg)
                        .listRowSeparator(.hidden)

                    if !collapsed {
                        ForEach(group.stickers) { sticker in
                            let count = counts[sticker.code] ?? 0
                            AlbumRowView(
                                sticker: sticker,
                                count: count,
                                style: style,
                                onToggleOwned: { toggleOwned(sticker.code) }
                            )
                            .listRowBackground(
                                StickerRowBackground(tint: style.accent, owned: count >= 1)
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button { adjust(sticker.code, by: 1) } label: {
                                    Label("Add copy", systemImage: "plus")
                                }
                                .tint(AppTheme.pitch)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button { adjust(sticker.code, by: -1) } label: {
                                    Label("Remove copy", systemImage: "minus")
                                }
                                .tint(AppTheme.spare)
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView {
                    Label("No stickers", systemImage: "magnifyingglass")
                } description: {
                    Text("Try changing the filters or search.")
                } actions: {
                    if viewModel.hasActiveFilters {
                        Button("Reset Filters") {
                            withAnimation {
                                viewModel.statusFilter = .all
                                viewModel.typeFilter = .all
                                viewModel.teamFilter = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.pitch)
                    }
                }
            }
        }
    }

    /// The album as printed pages — the physical album's layout, one page per swipe.
    private var pagesContent: some View {
        let byCode = entriesByCode
        return AlbumPagesView(
            stickers: viewModel.catalogInScope,
            counts: byCode.mapValues(\.count),
            nameOverrides: byCode.compactMapValues { $0.nameOverride },
            initialTeam: viewModel.teamFilter,
            onToggle: { toggleOwned($0) },
            onAdjust: { adjust($0, by: $1) }
        )
    }

    // MARK: - Entry lookup

    /// Current scope's entries, keyed by bare sticker code.
    private var entriesByCode: [String: StickerCollectionEntry] {
        scope.entriesByCode(entries)
    }

    /// The missing-stickers list for export (honors the active team filter).
    private var missingExportList: StickerExportList {
        let byCode = entriesByCode
        let counts = byCode.mapValues(\.count)
        let items = viewModel.missingStickers(counts: counts).map { s in
            StickerExportList.Item(
                code: s.code,
                number: s.number,
                name: s.displayTitle(override: byCode[s.code]?.nameOverride),
                team: s.teamCode != nil ? s.section : "",
                section: s.section,
                isFoil: s.isFoil,
                quantity: 1
            )
        }
        var title = String(localized: "\(scope.exportTitle) — Missing")
        if let teamFilter = viewModel.teamFilter,
           let team = viewModel.teams.first(where: { $0.code == teamFilter }) {
            title += " (\(team.name.localizedName))"
        }
        return StickerExportList(title: title, items: items, showQuantityInText: false)
    }

    private func entry(for code: String) -> StickerCollectionEntry? {
        let key = scope.storageKey(code)
        return entries.first { $0.stickerCode == key }
    }

    // MARK: - Mutations

    private func toggleSection(_ name: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if collapsedSections.contains(name) {
                collapsedSections.remove(name)
            } else {
                collapsedSections.insert(name)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ group: AlbumViewModel.SectionGroup,
                               progress p: (owned: Int, total: Int),
                               collapsed: Bool, style: AppTheme.FlagStyle) -> some View {
        let complete = p.total > 0 && p.owned == p.total
        let fg = style.fg
        let fraction = p.total > 0 ? Double(p.owned) / Double(p.total) : 0
        Button {
            toggleSection(group.name)
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.forward")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(fg.opacity(0.8))
                        .rotationEffect(.degrees(collapsed ? 0 : 90))
                        .frame(width: 10)

                    if let flag = group.flag, !flag.isEmpty {
                        Text(flag).font(.title3)
                    } else {
                        Image(systemName: sectionIcon(group.name))
                            .font(.subheadline)
                            .foregroundStyle(fg)
                    }

                    Text(LocalizedStringKey(group.name))
                        .font(.headline)
                        .foregroundStyle(fg)
                        .lineLimit(1)

                    if let letter = group.groupLetter {
                        Text("Group \(letter)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(fg)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(fg.opacity(0.2), in: Capsule())
                    }

                    Spacer()

                    if complete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.foilGradient)
                    }
                    Text("\(p.owned)/\(p.total)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(fg)
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(fg.opacity(0.25))
                        Capsule()
                            .fill(complete ? AnyShapeStyle(AppTheme.foilGradient) : AnyShapeStyle(fg))
                            .frame(width: geo.size.width * fraction)
                            .animation(.snappy(duration: 0.3), value: fraction)
                    }
                }
                .frame(height: 5)
            }
            .padding(.vertical, 5)
            .textCase(nil)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionIcon(_ name: String) -> String {
        switch name {
        case "Opening", "Intro":         return "flag.checkered"
        case "FIFA Museum":              return "trophy.fill"
        case "Trophy Tour":              return "trophy.fill"
        case "Coca-Cola", "#AllTheFeels": return "cup.and.saucer.fill"
        case "Host City Posters":        return "building.2.fill"
        case "Update Edition":           return "arrow.triangle.2.circlepath"
        case "Fan Stickers":             return "megaphone.fill"
        case "McDonald's":               return "fork.knife"
        default:                         return "shield.fill"
        }
    }


    private func setCount(_ code: String, to newValue: Int) {
        let value = max(0, newValue)
        withAnimation(.snappy(duration: 0.25)) {
            if let existing = entry(for: code) {
                existing.count = value
                existing.updatedAt = Date()
            } else if value > 0 {
                let new = StickerCollectionEntry(stickerCode: scope.storageKey(code), count: value)
                new.updatedAt = Date()
                modelContext.insert(new)
            }
            try? modelContext.save()
        }
    }

    private func toggleOwned(_ code: String) {
        setCount(code, to: (entry(for: code)?.count ?? 0) >= 1 ? 0 : 1)
    }

    private func adjust(_ code: String, by delta: Int) {
        setCount(code, to: (entry(for: code)?.count ?? 0) + delta)
    }

}
