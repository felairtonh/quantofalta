import SwiftUI

/// A labelled progress bar with an `owned/total` trailing count.
struct ProgressBarRow: View {
    let label: LocalizedStringKey
    let owned: Int
    let total: Int
    var tint: Color = .green

    private var fraction: Double { total > 0 ? Double(owned) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(minWidth: 56, alignment: .leading)
            ProgressView(value: fraction)
                .tint(tint)
            Text("\(owned)/\(total)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .trailing)
        }
    }
}
