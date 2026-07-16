#if DEBUG
import Foundation
import SwiftData

/// Debug-only seeding so screenshots/manual runs show realistic progress.
/// Triggered by launching with `-seedSampleData`. No effect in release builds.
@MainActor
enum SampleData {
    static func seedIfRequested(into container: ModelContainer) {
        guard CommandLine.arguments.contains("-seedSampleData") else { return }
        let context = container.mainContext

        let alreadySeeded = (try? context.fetchCount(FetchDescriptor<StickerCollectionEntry>())) ?? 0
        guard alreadySeeded == 0 else { return }

        var plan: [String: Int] = [:]
        for i in 1...20 { plan["MEX\(i)"] = 1 }          // a completed team
        for i in 1...16 { plan["BRA\(i)"] = 1 }          // partially done
        plan["BRA3"] = 3
        plan["BRA10"] = 2
        for i in [2, 3, 5, 6, 8, 9, 11, 14, 17, 18, 19] { plan["ARG\(i)"] = 1 }  // mixed, for demo
        plan["ARG5"] = 2
        plan["00"] = 1
        plan["FWC1"] = 1
        plan["FWC5"] = 2

        for (code, count) in plan {
            let entry = StickerCollectionEntry(stickerCode: code, count: count)
            entry.updatedAt = Date()
            context.insert(entry)
        }
        try? context.save()
    }
}
#endif
