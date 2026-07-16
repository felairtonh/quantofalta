import SwiftUI

/// First-launch walkthrough of the app's functions. Reopenable from
/// Settings → "Show welcome tour".
struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.pitchGradient)
                                .frame(width: 64, height: 64)
                            Image(systemName: "soccerball")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        Text("Welcome!")
                            .font(.largeTitle.bold())
                        Text("Your World Cup sticker manager!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 28)

                    feature(icon: "hand.tap", tint: AppTheme.pitch,
                            title: "Collect with a tap",
                            text: "Tap any sticker to mark it collected. Swipe a row (or press and hold a page slot) to manage spare copies.")

                    feature(icon: "book.pages", tint: AppTheme.foilDark,
                            title: "Pages view",
                            text: "The book icon shows the album as printed pages — swipe to flip through, exactly like the real album.")

                    feature(icon: "line.3.horizontal.decrease.circle", tint: AppTheme.group("F"),
                            title: "Filter, search & sort",
                            text: "Find missing stickers, Brilliants, or one team. Search by player name or number. Sort by album or A–Z.")

                    feature(icon: "square.on.square", tint: AppTheme.digital,
                            title: "Physical & Digital",
                            text: "Switch at the top of the Album and Duplicates tabs to track the FIFA Panini Collection app too.")

                    feature(icon: "rectangle.stack", tint: AppTheme.spare,
                            title: "Duplicates = trade list",
                            text: "Everything you own twice, with counts. Perfect for planning swaps.")

                    feature(icon: "square.and.arrow.up", tint: AppTheme.group("I"),
                            title: "Share lists",
                            text: "Export your Missing or Duplicates list as text or CSV — ready to paste into a group chat or swap request.")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Button {
                dismiss()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.pitch)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .presentationDragIndicator(.visible)
    }

    private func feature(icon: String, tint: Color,
                         title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
