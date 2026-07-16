import SwiftUI
import SwiftData
import TipKit
import OSLog

private let appLog = Logger(subsystem: "com.felipehunas.AlbumTracker", category: "app")

@main
struct AlbumTrackerApp: App {
    @State private var modelContainer: ModelContainer?

    init() {
        // Tips arm after the welcome tour; on later launches, immediately.
        if UserDefaults.standard.bool(forKey: "hasSeenWelcome") {
            AppTips.enable()
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                MainTabView()
                    .modelContainer(container)
                    .task {
                        #if DEBUG
                        SampleData.seedIfRequested(into: container)
                        #endif
                    }
            } else {
                ProgressView("Loading…")
                    .task { modelContainer = await Self.createContainer() }
            }
        }
    }

    /// Create the ModelContainer off the main thread, falling back to in-memory on failure.
    private static func createContainer() async -> ModelContainer {
        await Task.detached(priority: .userInitiated) {
            let schema = Schema([StickerCollectionEntry.self])
            let config = ModelConfiguration("AlbumTracker", isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                appLog.error("SwiftData store failed, falling back to in-memory: \(error.localizedDescription)")
                let fallback = ModelConfiguration("AlbumTracker", isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [fallback])
            }
        }.value
    }
}
