import SwiftUI

/// Generic privacy policy for a fully-local app: everything stays on device,
/// nothing is collected. Text lives in the string catalog (en / pt-BR).
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("Your data stays on your device",
                        "Everything you record in this app — collected stickers, duplicates, names and notes — is stored only on this device. Nothing is uploaded, synced or sent anywhere.")

                section("No accounts, no tracking",
                        "The app requires no account and collects no personal information. There are no analytics, no advertising identifiers and no third-party services.")

                section("Sharing is always your choice",
                        "The only data that ever leaves the app is what you explicitly share yourself, using the export buttons (missing and duplicates lists as text or CSV).")

                section("Deleting your data",
                        "Use \"Reset all progress\" in Settings, or simply delete the app — both remove everything permanently.")

                section("Changes",
                        "If a future version of the app changes any of this, the policy shown here will be updated before the change takes effect.")

                Text("Last updated: July 2026")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
