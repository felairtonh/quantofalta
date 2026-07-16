import Foundation
import OSLog

private let dataLog = Logger(subsystem: "com.felipehunas.AlbumTracker", category: "data")

/// All file I/O and JSON decoding for the bundled catalog happens off the main thread.
actor BundledDataLoader {
    private let albumId: String

    init(albumId: String = "world-cup-2026") {
        self.albumId = albumId
    }

    func loadStickers() -> [Sticker] {
        load("stickers") ?? []
    }

    private func load<T: Decodable>(_ filename: String) -> T? {
        guard let url = Bundle.main.url(
            forResource: filename, withExtension: "json",
            subdirectory: "BundledData/\(albumId)"
        ) else {
            dataLog.error("Resource not found: BundledData/\(self.albumId)/\(filename).json")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            dataLog.error("Failed to read: \(url.path, privacy: .public)")
            return nil
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            dataLog.error("Decode error for \(filename).json: \(error.localizedDescription)")
            return nil
        }
    }
}
