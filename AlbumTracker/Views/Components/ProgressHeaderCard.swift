import SwiftUI

/// The dashboard card at the top of the Album tab: a gold completion ring on a
/// pitch-green gradient, plus collected / Brilliant / spare stats.
struct ProgressHeaderCard: View {
    let owned: Int
    let total: Int
    let brilliantOwned: Int
    let brilliantTotal: Int
    let spares: Int

    private var fraction: Double { total > 0 ? Double(owned) / Double(total) : 0 }
    private var percent: Int { Int((fraction * 100).rounded()) }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.22), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(AppTheme.foilGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: fraction)
                Text("\(percent)%")
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(owned) / \(total)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("stickers collected")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                HStack(spacing: 8) {
                    chip(icon: "sparkles", text: "\(brilliantOwned)/\(brilliantTotal) Brilliant")
                    chip(icon: "rectangle.stack.fill", text: "\(spares) spare")
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background {
            ZStack(alignment: .topTrailing) {
                AppTheme.pitchGradient
                Image(systemName: "soccerball")
                    .font(.system(size: 130))
                    .foregroundStyle(.white.opacity(0.07))
                    .rotationEffect(.degrees(-14))
                    .offset(x: 36, y: -10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.pitchDark.opacity(0.25), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(percent) percent complete. \(owned) of \(total) stickers collected. \(brilliantOwned) of \(brilliantTotal) Brilliant. \(spares) spare.")
    }

    private func chip(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(text).font(.caption2.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.18), in: Capsule())
    }
}
