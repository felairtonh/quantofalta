import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                AlbumView()
            }
            .tabItem {
                Label("Album", systemImage: "square.grid.3x3.fill")
            }
            .tag(0)

            NavigationStack {
                DuplicatesView()
            }
            .tabItem {
                Label("Duplicates", systemImage: "rectangle.stack.fill")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .sheet(isPresented: Binding(get: { !hasSeenWelcome },
                                    set: { hasSeenWelcome = !$0 }),
               onDismiss: { AppTips.enable() }) {
            WelcomeView()
        }
        .task {
            #if DEBUG
            if let raw = ProcessInfo.processInfo.environment["START_TAB"], let idx = Int(raw) {
                selection = idx
            }
            #endif
        }
    }
}
