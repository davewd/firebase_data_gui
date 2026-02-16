import SwiftUI
import AppKit
import Foundation
@main
struct FirebaseDataGUIApp: App {
    @StateObject private var appState = AppState()

    init() {
        DockIcon.apply()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

private enum DockIcon {
    private static let emoji = "🔥"
    private static let resourceName = "DockIcon"
    private static let iconSize = NSSize(width: 256, height: 256)

    static func apply() {
        NSApplication.shared.applicationIconImage = loadImage() ?? makeImage()
    }

    private static func loadImage() -> NSImage? {
        guard let url = resourceBundle.url(forResource: resourceName, withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    private static func makeImage() -> NSImage {
        NSImage(size: iconSize, flipped: false) { _ in
            let font = NSFont.systemFont(ofSize: iconSize.width * 0.78)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font
            ]
            let emojiString = emoji as NSString
            let emojiSize = emojiString.size(withAttributes: attributes)
            let origin = CGPoint(
                x: (iconSize.width - emojiSize.width) / 2,
                y: (iconSize.height - emojiSize.height) / 2
            )
            emojiString.draw(at: origin, withAttributes: attributes)
            return true
        }
    }

    private static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var firebaseManager: FirebaseManager?
    @Published var cachedAuthenticationError: String?
}
