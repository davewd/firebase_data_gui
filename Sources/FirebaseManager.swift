import Foundation
import Security
import os

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
    private static let logger = Logger(subsystem: "FirebaseDataGUI", category: "Authentication")

    private enum ErrorCode: Int {
        case tokenRequest = 6
        case jwtEncoding = 7
        case privateKeyLoad = 8
        case jwtSign = 9
        case privateKeyDecode = 10
        case tokenExpiry = 11
        case privateKeyPkcs1 = 12
        case privateKeyMissingPem = 13
    }
    
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
        Self.logger.info("Decoding service account from file \(serviceKeyURL.lastPathComponent, privacy: .private).")
        let data = try Data(contentsOf: serviceKeyURL)
        let decoder = JSONDecoder()
        let account = try decoder.decode(ServiceAccount.self, from: data)
        try initialize(with: account)
    }

    /// Initializes the manager with a decoded service account payload.
    /// - Parameter serviceAccount: A validated service account model.
    /// - Throws: An error if required fields are empty.
    internal func initialize(with serviceAccount: ServiceAccount) throws {
        Self.logger.info("Validating service account fields for initialization.")
        let requiredFields = [
            ("project ID", serviceAccount.projectId.trimmingCharacters(in: Self.trimmedCharacters)),
            ("private key", serviceAccount.privateKey.trimmingCharacters(in: Self.trimmedCharacters)),
            ("client email", serviceAccount.clientEmail.trimmingCharacters(in: Self.trimmedCharacters))
        ]
        let missingFields = requiredFields.filter { $0.1.isEmpty }.map { $0.0 }
        if !missingFields.isEmpty {
            Self.logger.error("Service account validation failed. Missing fields: \(missingFields.joined(separator: ", "), privacy: .public)")
            throw NSError(
                domain: "FirebaseDataGUI",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Service account data missing required fields: \(missingFields.joined(separator: ", "))"]
            )
        }
        self.serviceAccount = serviceAccount
        self.cachedToken = nil
        Self.logger.info("Service account stored for project \(serviceAccount.projectId, privacy: .public).")
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
                self.error = userMessage(for: error)
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
            Self.logger.info("Using cached OAuth token. Expires at \(cachedToken.expiry, privacy: .private).")
            return cachedToken.value
        }
        guard let serviceAccount else {
            throw NSError(domain: "FirebaseDataGUI", code: 4, userInfo: [NSLocalizedDescriptionKey: "Service account not initialized."])
        }

        Self.logger.info("Generating signed JWT for \(serviceAccount.clientEmail, privacy: .private).")
        let jwt = try makeSignedJWT(from: serviceAccount)
        Self.logger.info("JWT generated. Preparing token request.")
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

        Self.logger.info("Requesting OAuth token from \(Self.tokenEndpoint, privacy: .public).")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? Self.unknownStatusCode
            Self.logger.error("Token request failed with HTTP status \(statusCode, privacy: .public).")
            throw NSError(
                domain: "FirebaseDataGUI",
                code: ErrorCode.tokenRequest.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: "Token request failed with HTTP status \(statusCode).",
                    "HTTPStatusCode": statusCode
                ]
            )
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        guard tokenResponse.expiresIn > 0 else {
            throw NSError(domain: "FirebaseDataGUI", code: ErrorCode.tokenExpiry.rawValue, userInfo: [NSLocalizedDescriptionKey: "Token response did not include a valid expiry."])
        }
        let expiry = Date().addingTimeInterval(tokenResponse.expiresIn)
        let token = OAuthToken(value: tokenResponse.accessToken, expiry: expiry)
        cachedToken = token
        Self.logger.info("OAuth token received. Expires in \(tokenResponse.expiresIn, privacy: .public) seconds.")
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
        Self.logger.info("Building JWT header and claims.")
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
        Self.logger.info("Signing JWT.")
        let signature = try sign(input: signingInput, privateKey: account.privateKey)
        Self.logger.info("JWT signed successfully.")
        return "\(signingInput).\(signature)"
    }

    private func sign(input: String, privateKey: String) throws -> String {
        guard let messageData = input.data(using: .utf8) else {
            throw NSError(domain: "FirebaseDataGUI", code: ErrorCode.jwtEncoding.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unable to encode JWT input."])
        }
        Self.logger.info("Loading private key for JWT signing.")
        let keyData = try privateKeyData(from: privateKey)
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            let message = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw NSError(domain: "FirebaseDataGUI", code: ErrorCode.privateKeyLoad.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unable to load private key: \(message)"])
        }
        guard let signature = SecKeyCreateSignature(
            secKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            messageData as CFData,
            &error
        ) as Data? else {
            let message = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw NSError(domain: "FirebaseDataGUI", code: ErrorCode.jwtSign.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unable to sign JWT: \(message)"])
        }
        Self.logger.info("JWT signature created.")
        return base64URLEncoded(signature)
    }

    private func privateKeyData(from pemKey: String) throws -> Data {
        let normalizedKey = pemKey
            .replacingOccurrences(of: "\\r\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "")
            .replacingOccurrences(of: "\\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedKey.contains("-----BEGIN RSA PRIVATE KEY-----") {
            throw NSError(
                domain: "FirebaseDataGUI",
                code: ErrorCode.privateKeyPkcs1.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Private key is in PKCS#1 format. Firebase service account keys use PKCS#8 (-----BEGIN PRIVATE KEY-----). Download a new service account JSON key."]
            )
        }
        guard normalizedKey.contains("-----BEGIN PRIVATE KEY-----"),
              normalizedKey.contains("-----END PRIVATE KEY-----") else {
            throw NSError(
                domain: "FirebaseDataGUI",
                code: ErrorCode.privateKeyMissingPem.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Private key is missing the expected PEM header/footer. Use the unmodified service account JSON key downloaded from Firebase."]
            )
        }
        let cleanedKey = normalizedKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
        guard let keyData = Data(base64Encoded: cleanedKey) else {
            throw NSError(domain: "FirebaseDataGUI", code: ErrorCode.privateKeyDecode.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unable to decode private key."])
        }
        return keyData
    }

    private func userMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == "FirebaseDataGUI" {
            switch nsError.code {
            case ErrorCode.jwtEncoding.rawValue,
                 ErrorCode.privateKeyLoad.rawValue,
                 ErrorCode.jwtSign.rawValue,
                 ErrorCode.privateKeyDecode.rawValue,
                 ErrorCode.privateKeyPkcs1.rawValue,
                 ErrorCode.privateKeyMissingPem.rawValue:
                return ErrorReporter.userMessage(
                    errorType: "Service Account Key Invalid",
                    resolution: "Use the unmodified Firebase service account JSON key (PKCS#8 format). If you see \\n in the key text, replace it with actual newline characters.",
                    underlying: error
                )
            case ErrorCode.tokenRequest.rawValue, ErrorCode.tokenExpiry.rawValue:
                return ErrorReporter.userMessage(
                    errorType: "Authentication Failed",
                    resolution: "Verify the service account has access to Firebase and your system clock is correct before trying again.",
                    underlying: error
                )
            default:
                break
            }
        }
        return ErrorReporter.userMessage(
            errorType: "Database Fetch Failed",
            resolution: "Confirm your database URL and security rules allow public read.",
            underlying: error
        )
    }

    private func base64URLEncoded(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
