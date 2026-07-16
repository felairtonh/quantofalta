import SwiftUI
import TipKit

/// The album as flippable printed pages — every slot where it sits in the
/// physical album (Brazilian edition). Swipe to turn pages (with a book-like
/// page-turn effect); tap a slot to collect it; long-press for copies.
///
/// Performance: pages scroll in a lazy paging `ScrollView`, so only the pages
/// near the viewport exist at all, and the page structure is cached per
/// catalog — never rebuilt per render.
struct AlbumPagesView: View {
    let stickers: [Sticker]
    let counts: [String: Int]
    let nameOverrides: [String: String]
    var initialTeam: String?
    let onToggle: (String) -> Void
    let onAdjust: (String, Int) -> Void

    @State private var selection: String?
    @State private var pages: [AlbumPage] = []
    @State private var indexById: [String: Int] = [:]
    @State private var sections: [SectionEntry] = []
    @State private var codesBySection: [String: [String]] = [:]
    @State private var editingSticker: Sticker?

    private struct SectionEntry: Identifiable {
        let name: String
        let flag: String?
        let pageId: String
        var id: String { pageId }
    }

    private let slotSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            TipView(AppTips.PageSwipe())
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            pager
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                jumpMenu
            }
        }
        .task(id: stickers.count) {
            rebuildPageCache()
            ensureValidSelection()
            #if DEBUG
            if let code = ProcessInfo.processInfo.environment["SHOW_COPIES"],
               let sticker = stickers.first(where: { $0.code == code }) {
                editingSticker = sticker
            }
            #endif
        }
        .sheet(item: $editingSticker) { sticker in
            CopiesEditorSheet(
                sticker: sticker,
                count: counts[sticker.code] ?? 0,
                style: AppTheme.sectionStyle(name: sticker.section, teamCode: sticker.teamCode),
                nameOverride: nameOverrides[sticker.code],
                onAdjust: { onAdjust(sticker.code, $0) }
            )
        }
    }

    private var pager: some View {
        GeometryReader { geo in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(pages) { page in
                        ScrollView {
                            pageCard(page, availableWidth: geo.size.width - 32,
                                     pageIndex: indexById[page.id] ?? 0,
                                     pageCount: pages.count)
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                                .padding(.bottom, 16)
                        }
                        .frame(width: geo.size.width)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            // Book-style page turn: the incoming/outgoing page
                            // rotates around its outer edge and dims slightly.
                            content
                                .rotation3DEffect(
                                    .degrees(phase.value * -40),
                                    axis: (x: 0, y: 1, z: 0),
                                    anchor: phase.value < 0 ? .trailing : .leading,
                                    perspective: 0.8
                                )
                                .opacity(1 - abs(phase.value) * 0.3)
                                .brightness(phase.isIdentity ? 0 : -0.05 * abs(phase.value))
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selection)
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Cached page structure

    /// Derives everything that depends only on the catalog. Runs once per
    /// catalog change, never per render.
    private func rebuildPageCache() {
        let built = AlbumPageBuilder.pages(from: stickers)
        pages = built
        indexById = Dictionary(uniqueKeysWithValues: built.enumerated().map { ($1.id, $0) })

        var seen = Set<String>()
        sections = built.compactMap { page in
            guard seen.insert(page.section).inserted else { return nil }
            return SectionEntry(name: page.section, flag: page.flag, pageId: page.id)
        }

        var codes: [String: [String]] = [:]
        for page in built {
            codes[page.section, default: []].append(contentsOf: page.stickers.map(\.code))
        }
        codesBySection = codes
    }

    private func ensureValidSelection() {
        #if DEBUG
        if let id = ProcessInfo.processInfo.environment["START_PAGE"], !id.isEmpty,
           indexById[id] != nil {
            selection = id
            return
        }
        #endif
        if let team = initialTeam, selection == nil,
           let page = pages.first(where: { $0.teamCode == team }) {
            selection = page.id
        } else if selection == nil || indexById[selection ?? ""] == nil {
            selection = pages.first?.id
        }
    }

    // MARK: - Navigation

    private var jumpMenu: some View {
        let current = selection.flatMap { indexById[$0] }.map { pages[$0] }

        return Menu {
            ForEach(sections) { section in
                Button {
                    withAnimation(.smooth(duration: 0.55)) { selection = section.pageId }
                } label: {
                    if let flag = section.flag {
                        Text("\(flag)  \(section.name.localizedName)")
                    } else {
                        Text(LocalizedStringKey(section.name))
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                if let flag = current?.flag { Text(flag) }
                Text(LocalizedStringKey(current?.section ?? "Album"))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
        }
    }

    // MARK: - Page rendering

    private func pageCard(_ page: AlbumPage, availableWidth: CGFloat,
                          pageIndex: Int, pageCount: Int) -> some View {
        let style = AppTheme.sectionStyle(name: page.section, teamCode: page.teamCode)
        let contentWidth = availableWidth - 28              // card's inner padding
        let unitWidth = (contentWidth - slotSpacing * CGFloat(page.columns - 1))
            / CGFloat(page.columns)
        let slotHeight = min(unitWidth * 1.3, 150)

        return VStack(spacing: 0) {
            // Decorative team-color band, like the printed page's top waves.
            LinearGradient(colors: [style.bg, style.accent],
                           startPoint: .leading, endPoint: .trailing)
                .frame(height: 8)

            VStack(spacing: 12) {
                if page.teamCode == nil {
                    sectionTitleRow(page, style: style)
                }

                ForEach(Array(page.rows.enumerated()), id: \.offset) { _, row in
                    rowView(row, unitWidth: unitWidth, slotHeight: slotHeight, style: style)
                }

                footer(page, pageIndex: pageIndex, pageCount: pageCount, style: style)
            }
            .padding(14)
        }
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 7, y: 3)
    }

    private func rowView(_ row: [AlbumPage.Item], unitWidth: CGFloat,
                         slotHeight: CGFloat, style: AppTheme.FlagStyle) -> some View {
        HStack(alignment: .top, spacing: slotSpacing) {
            ForEach(row) { item in
                itemView(item, slotHeight: slotHeight, style: style)
                    .frame(width: unitWidth * CGFloat(item.units)
                           + slotSpacing * CGFloat(item.units - 1))
            }
        }
        .frame(maxWidth: .infinity, alignment: row.count == 1 ? .center : .leading)
    }

    @ViewBuilder
    private func itemView(_ item: AlbumPage.Item, slotHeight: CGFloat,
                          style: AppTheme.FlagStyle) -> some View {
        switch item {
        case .slot(let sticker), .photoSlot(let sticker):
            PageStickerSlot(
                sticker: sticker,
                count: counts[sticker.code] ?? 0,
                style: style,
                nameOverride: nameOverrides[sticker.code],
                slotHeight: slotHeight,
                onToggle: { onToggle(sticker.code) },
                onAdjust: { onAdjust(sticker.code, $0) },
                onLongPress: { editingSticker = sticker }
            )

        case .teamHeader(let name, let flag, let group):
            VStack(alignment: .leading, spacing: 4) {
                Text("WE ARE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(style.fg.opacity(0.85))
                Text(name.uppercased())
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.45)
                    .lineLimit(2)
                    .foregroundStyle(style.fg)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    if let flag { Text(flag).font(.title3) }
                    if let group {
                        Text("Group \(group)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(style.fg)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(style.fg.opacity(0.2), in: Capsule())
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: slotHeight + 28)
            .background(
                LinearGradient(colors: [style.bg, style.bg.opacity(0.85)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous))

        case .groupBox(let letter, let flags):
            VStack(spacing: 5) {
                Text("GROUP")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text(letter)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.group(letter))
                if !flags.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(flags.prefix(2), id: \.self) { Text($0) }
                    }
                    .font(.caption2)
                    HStack(spacing: 2) {
                        ForEach(flags.dropFirst(2), id: \.self) { Text($0) }
                    }
                    .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: slotHeight + 28)
            .background(Color.primary.opacity(0.045),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Group \(letter)")
        }
    }

    private func sectionTitleRow(_ page: AlbumPage, style: AppTheme.FlagStyle) -> some View {
        HStack(spacing: 8) {
            Image(systemName: sectionIcon(page.section))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(style.accent)
            Text(page.section.localizedName.uppercased())
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.top, 2)
    }

    private func footer(_ page: AlbumPage, pageIndex: Int, pageCount: Int,
                        style: AppTheme.FlagStyle) -> some View {
        // Only live (near-viewport) pages pay this: one pass over ~20 codes.
        let sectionCodes = codesBySection[page.section] ?? []
        let owned = sectionCodes.reduce(0) { $0 + ((counts[$1] ?? 0) >= 1 ? 1 : 0) }
        let fraction = sectionCodes.isEmpty ? 0 : Double(owned) / Double(sectionCodes.count)
        let complete = !sectionCodes.isEmpty && owned == sectionCodes.count

        return VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.09))
                    Capsule()
                        .fill(complete ? AnyShapeStyle(AppTheme.foilGradient)
                                       : AnyShapeStyle(style.accent))
                        .frame(width: geo.size.width * fraction)
                        .animation(.snappy(duration: 0.3), value: fraction)
                }
            }
            .frame(height: 4)

            HStack {
                if let subtitle = page.subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if complete {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.foilGradient)
                }
                Text("\(owned)/\(sectionCodes.count)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                Spacer()
                Text("Page \(pageIndex + 1) of \(pageCount)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 2)
    }

    private func sectionIcon(_ name: String) -> String {
        switch name {
        case "Opening":     return "flag.checkered"
        case "FIFA Museum": return "trophy.fill"
        case "Coca-Cola":   return "cup.and.saucer.fill"
        default:            return "shield.fill"
        }
    }

    /// Cream "paper" in light mode, deep neutral in dark.
    private var paper: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.13, alpha: 1)
                : UIColor(red: 0.980, green: 0.963, blue: 0.925, alpha: 1)
        })
    }
}

/// Copies editor opened by long-pressing a slot in the pages view. A plain
/// sheet with oversized +/- targets — a context menu here would freeze against
/// the pager's 3D scroll transition, and its rows were too small to hit.
private struct CopiesEditorSheet: View {
    let sticker: Sticker
    let count: Int
    let style: AppTheme.FlagStyle
    var nameOverride: String?
    let onAdjust: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 14) {
                PageStickerSlot(
                    sticker: sticker, count: count, style: style,
                    nameOverride: nameOverride, slotHeight: 84,
                    onToggle: {}, onAdjust: { _ in }
                )
                .frame(width: 74)
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 3) {
                    Text(sticker.code)
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(sticker.displayTitle(override: nameOverride))
                        .font(.headline)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 26) {
                Button {
                    onAdjust(-1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(count <= 0 ? Color.secondary.opacity(0.35)
                                                    : AppTheme.spare)
                        .frame(width: 72, height: 72)
                        .contentShape(Rectangle())
                }
                .disabled(count <= 0)
                .accessibilityLabel("Remove copy")

                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: count)
                    Text("copies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 84)

                Button {
                    onAdjust(1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppTheme.pitch)
                        .frame(width: 72, height: 72)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Add copy")
            }
            .sensoryFeedback(.increase, trigger: count) { old, new in new > old }
            .sensoryFeedback(.decrease, trigger: count) { old, new in new < old }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.pitch)
        }
        .padding(20)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}
