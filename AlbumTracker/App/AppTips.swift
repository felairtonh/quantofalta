import TipKit

/// Contextual TipKit tips introducing the app's controls.
///
/// At most ONE popover tip exists per screen: presenting several popovers
/// simultaneously on the same screen (as separate filter/view/switcher tips
/// once did) collides in UIKit presentation and freezes the app. The pages
/// tip is inline (`TipView`), which never presents.
///
/// Tips also arm only after the welcome tour is dismissed AND its dismissal
/// animation has settled — presenting a popover mid-transition hangs too.
@MainActor
enum AppTips {
    private static var configured = false

    /// Idempotent; called at launch when the welcome was already seen, and
    /// when the welcome sheet is dismissed on first run.
    static func enable() {
        #if DEBUG
        // Keeps marketing screenshots clean (see DataPipeline/make_icon.py's
        // sibling workflow in the README).
        if ProcessInfo.processInfo.environment["DISABLE_TIPS"] != nil { return }
        #endif
        guard !configured else { return }
        configured = true
        Task { @MainActor in
            // Let the welcome sheet's dismissal transition finish first.
            try? await Task.sleep(for: .seconds(0.7))
            try? Tips.configure([.displayFrequency(.immediate)])
        }
    }

    /// Single tip for the Album tab's controls (filter, pages view, album
    /// switcher) — the welcome tour explains each in detail.
    struct Controls: Tip {
        var title: Text { Text("Explore the controls") }
        var message: Text? {
            Text("Filter and sort stickers, open the album as pages with the book icon, and switch between Physical and Digital at the top.")
        }
        var image: Image? { Image(systemName: "slider.horizontal.3") }
    }

    struct PageSwipe: Tip {
        var title: Text { Text("Flip through the album") }
        var message: Text? {
            Text("Swipe to turn pages. Tap a slot to collect it; press and hold to manage copies.")
        }
        var image: Image? { Image(systemName: "hand.draw") }
    }

    struct AddDuplicate: Tip {
        var title: Text { Text("Your trade list") }
        var message: Text? {
            Text("Add stickers you own twice. Everything with spares shows here — export it when arranging swaps.")
        }
        var image: Image? { Image(systemName: "rectangle.stack.badge.plus") }
    }
}
