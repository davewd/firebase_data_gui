import SwiftUI

@main
struct FirebaseDataGUIApp: App {
    @StateObject private var appState = AppState()
    
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

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var firebaseManager: FirebaseManager?
}
