import Foundation
import CryptoKit

class FirebaseManager: ObservableObject {
    @Published var data: [String: Any] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private var serviceAccount: ServiceAccount?
    
    struct ServiceAccount: Codable {
        let projectId: String
        let privateKey: String
        let clientEmail: String
        let databaseURL: String?
        
        enum CodingKeys: String, CodingKey {
            case projectId = "project_id"
            case privateKey = "private_key"
            case clientEmail = "client_email"
            case databaseURL = "database_url"
        }
    }
    
    func initialize(with serviceKeyURL: URL) throws {
        let data = try Data(contentsOf: serviceKeyURL)
        let decoder = JSONDecoder()
        let account = try decoder.decode(ServiceAccount.self, from: data)
        initialize(with: account)
    }

    func initialize(with serviceAccount: ServiceAccount) {
        self.serviceAccount = serviceAccount
    }
    
    private var databaseURL: String {
        if let url = serviceAccount?.databaseURL, !url.isEmpty {
            return url
        }
        // Default database URL format
        if let projectId = serviceAccount?.projectId {
            return "https://\(projectId)-default-rtdb.firebaseio.com"
        }
        return ""
    }
    
    func fetchRootData() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Note: This implementation uses public read access to the Firebase Realtime Database.
            // For production use, implement OAuth 2.0 token generation from the service account
            // credentials to authenticate requests.
            let baseURL = databaseURL
            guard !baseURL.isEmpty else {
                throw NSError(domain: "FirebaseDataGUI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to construct database URL from configuration"])
            }
            
            // Construct the URL to fetch root data (limited via shallow query)
            let urlString = "\(baseURL)/.json?shallow=true"
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "FirebaseDataGUI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "FirebaseDataGUI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch data"])
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Get the keys and fetch first 5 with their values
                let keys = Array(json.keys.sorted().prefix(5))
                var detailedData: [String: Any] = [:]
                
                for key in keys {
                    if let value = await fetchData(at: key) {
                        detailedData[key] = value
                    }
                }
                
                let finalData = detailedData
                await MainActor.run {
                    self.data = finalData
                }
            } else {
                await MainActor.run {
                    self.data = [:]
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch data: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func fetchData(at path: String) async -> Any? {
        do {
            let urlString = "\(databaseURL)/\(path).json?limitToFirst=5"
            guard let url = URL(string: urlString) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch data at \(path): \(error.localizedDescription)"
            }
            return nil
        }
    }
}
