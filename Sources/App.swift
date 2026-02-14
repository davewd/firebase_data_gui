import SwiftUI
import Security
import os

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
    private static let keychainService = "FirebaseDataGUI"
    private static let keychainAccount = "serviceAccount"
    private static let logger = Logger(subsystem: "FirebaseDataGUI", category: "Authentication")

    init() {
        loadCachedServiceAccount()
    }

    func cacheServiceAccount(_ serviceAccount: FirebaseManager.ServiceAccount) {
        do {
            let data = try JSONEncoder().encode(serviceAccount)
            try saveServiceAccountData(data)
            Self.logger.info("Cached service account in Keychain.")
        } catch {
            Self.logger.error("Failed to cache service account. \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadCachedServiceAccount() {
        do {
            guard let data = try loadServiceAccountData() else { return }
            let serviceAccount = try JSONDecoder().decode(FirebaseManager.ServiceAccount.self, from: data)
            let manager = FirebaseManager()
            try manager.initialize(with: serviceAccount)
            firebaseManager = manager
            isAuthenticated = true
            Self.logger.info("Loaded cached service account from Keychain.")
        } catch {
            Self.logger.error("Failed to load cached service account. \(error.localizedDescription, privacy: .public)")
            clearCachedServiceAccount()
        }
    }

    private func clearCachedServiceAccount() {
        let query = keychainQuery()
        SecItemDelete(query as CFDictionary)
    }

    private func keychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
    }

    private func saveServiceAccountData(_ data: Data) throws {
        var query = keychainQuery()
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(
                domain: "FirebaseDataGUI",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Keychain save failed with status \(status)."]
            )
        }
    }

    private func loadServiceAccountData() throws -> Data? {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw NSError(
                domain: "FirebaseDataGUI",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Keychain read failed with status \(status)."]
            )
        }
        return item as? Data
    }
}
