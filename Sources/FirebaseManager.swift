import Foundation
import Security

class FirebaseManager: ObservableObject {
    @Published var data: [String: Any] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private var serviceAccount: ServiceAccount?
    private var cachedToken: OAuthToken?
    private static let trimmedCharacters = CharacterSet.whitespacesAndNewlines
    private static let unknownStatusCode = -1
    private static let tokenEndpoint = "https://oauth2.googleapis.com/token"
    private static let tokenScope = "https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email"
    private static let tokenExpiryBufferSeconds: TimeInterval = 60
    private static let jwtExpirationSeconds = 3600
    
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

    private struct OAuthToken {
        let value: String
        let expiry: Date
    }
    
    internal func initialize(with serviceKeyURL: URL) throws {
        let data = try Data(contentsOf: serviceKeyURL)
        let decoder = JSONDecoder()
        let account = try decoder.decode(ServiceAccount.self, from: data)
        try initialize(with: account)
    }

    /// Initializes the manager with a decoded service account payload.
    /// - Parameter serviceAccount: A validated service account model.
    /// - Throws: An error if required fields are empty.
    internal func initialize(with serviceAccount: ServiceAccount) throws {
        let requiredFields = [
            ("project ID", serviceAccount.projectId.trimmingCharacters(in: Self.trimmedCharacters)),
            ("private key", serviceAccount.privateKey.trimmingCharacters(in: Self.trimmedCharacters)),
            ("client email", serviceAccount.clientEmail.trimmingCharacters(in: Self.trimmedCharacters))
        ]
        let missingFields = requiredFields.filter { $0.1.isEmpty }.map { $0.0 }
        if !missingFields.isEmpty {
            throw NSError(
                domain: "FirebaseDataGUI",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Service account data missing required fields: \(missingFields.joined(separator: ", "))"]
            )
        }
        self.serviceAccount = serviceAccount
        self.cachedToken = nil
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
            let resolvedDatabaseURL = databaseURL
            guard !resolvedDatabaseURL.isEmpty else {
                throw NSError(domain: "FirebaseDataGUI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to construct database URL from configuration"])
            }

            let accessToken = try await accessToken()
            
            // Construct the URL to fetch root data (limited via shallow query)
            let urlString = "\(resolvedDatabaseURL)/.json?shallow=true"
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "FirebaseDataGUI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? Self.unknownStatusCode
                throw NSError(
                    domain: "FirebaseDataGUI",
                    code: 3,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Received HTTP status \(statusCode).",
                        "HTTPStatusCode": statusCode
                    ]
                )
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Get the keys and fetch first 5 with their values
                let keys = Array(json.keys.sorted().prefix(5))
                var detailedData: [String: Any] = [:]
                
                for key in keys {
                    if let value = await fetchData(at: key, accessToken: accessToken) {
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
                self.error = ErrorReporter.userMessage(
                    errorType: "Database Fetch Failed",
                    resolution: "Confirm your database URL and security rules allow public read.",
                    underlying: error
                )
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func fetchData(at path: String, accessToken: String) async -> Any? {
        do {
            let urlString = "\(databaseURL)/\(path).json?limitToFirst=5"
            guard let url = URL(string: urlString) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            await MainActor.run {
                self.error = ErrorReporter.userMessage(
                    errorType: "Data Fetch Failed",
                    resolution: "Verify the selected path exists and your database allows public reads.",
                    details: "Path: \(path)",
                    underlying: error
                )
            }
            return nil
        }
    }

    private func accessToken() async throws -> String {
        if let cachedToken, cachedToken.expiry > Date().addingTimeInterval(Self.tokenExpiryBufferSeconds) {
            return cachedToken.value
        }
        guard let serviceAccount else {
            throw NSError(domain: "FirebaseDataGUI", code: 4, userInfo: [NSLocalizedDescriptionKey: "Service account not initialized."])
        }

        let jwt = try makeSignedJWT(from: serviceAccount)
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "urn:ietf:params:oauth:grant-type:jwt-bearer"),
            URLQueryItem(name: "assertion", value: jwt)
        ]
        guard let body = components.percentEncodedQuery?.data(using: .utf8),
              let tokenURL = URL(string: Self.tokenEndpoint) else {
            throw NSError(domain: "FirebaseDataGUI", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to build token request."])
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? Self.unknownStatusCode
            throw NSError(
                domain: "FirebaseDataGUI",
                code: 6,
                userInfo: [
                    NSLocalizedDescriptionKey: "Token request failed with HTTP status \(statusCode).",
                    "HTTPStatusCode": statusCode
                ]
            )
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        guard tokenResponse.expiresIn > 0 else {
            throw NSError(domain: "FirebaseDataGUI", code: 11, userInfo: [NSLocalizedDescriptionKey: "Token response did not include a valid expiry."])
        }
        let expiry = Date().addingTimeInterval(tokenResponse.expiresIn)
        let token = OAuthToken(value: tokenResponse.accessToken, expiry: expiry)
        cachedToken = token
        return token.value
    }

    private struct OAuthTokenResponse: Decodable {
        let accessToken: String
        let expiresIn: TimeInterval

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
        }
    }

    private func makeSignedJWT(from account: ServiceAccount) throws -> String {
        let header: [String: String] = ["alg": "RS256", "typ": "JWT"]
        let issuedAt = Int(Date().timeIntervalSince1970)
        let expiration = issuedAt + Self.jwtExpirationSeconds
        let claims: [String: Any] = [
            "iss": account.clientEmail,
            "scope": Self.tokenScope,
            "aud": Self.tokenEndpoint,
            "iat": issuedAt,
            "exp": expiration
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
        let claimsData = try JSONSerialization.data(withJSONObject: claims, options: [])
        let encodedHeader = base64URLEncoded(headerData)
        let encodedClaims = base64URLEncoded(claimsData)
        let signingInput = "\(encodedHeader).\(encodedClaims)"
        let signature = try sign(input: signingInput, privateKey: account.privateKey)
        return "\(signingInput).\(signature)"
    }

    private func sign(input: String, privateKey: String) throws -> String {
        guard let messageData = input.data(using: .utf8) else {
            throw NSError(domain: "FirebaseDataGUI", code: 7, userInfo: [NSLocalizedDescriptionKey: "Unable to encode JWT input."])
        }
        let keyData = try privateKeyData(from: privateKey)
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            let message = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw NSError(domain: "FirebaseDataGUI", code: 8, userInfo: [NSLocalizedDescriptionKey: "Unable to load private key: \(message)"])
        }
        guard let signature = SecKeyCreateSignature(
            secKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            messageData as CFData,
            &error
        ) as Data? else {
            let message = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw NSError(domain: "FirebaseDataGUI", code: 9, userInfo: [NSLocalizedDescriptionKey: "Unable to sign JWT: \(message)"])
        }
        return base64URLEncoded(signature)
    }

    private func privateKeyData(from pemKey: String) throws -> Data {
        let cleanedKey = pemKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        guard let keyData = Data(base64Encoded: cleanedKey) else {
            throw NSError(domain: "FirebaseDataGUI", code: 10, userInfo: [NSLocalizedDescriptionKey: "Unable to decode private key."])
        }
        return keyData
    }

    private func base64URLEncoded(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
