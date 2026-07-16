import SwiftUI

/// A compact −/N/+ control for adjusting how many copies of a sticker you own.
struct CopiesStepper: View {
    let count: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            Button(action: onDecrement) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(count <= 0 ? Color.secondary.opacity(0.4) : Color.accentColor)
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(count <= 0)

            Text("\(count)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 26)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.2), value: count)

            Button(action: onIncrement) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .font(.title2)
        .sensoryFeedback(.increase, trigger: count) { old, new in new > old }
        .sensoryFeedback(.decrease, trigger: count) { old, new in new < old }
    }
}
