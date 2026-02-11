import Foundation
import os

struct ErrorReporter {
    private static let logger = Logger(subsystem: "FirebaseDataGUI", category: "Errors")
    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        return formatter
    }
    
    static func userMessage(
        errorType: String,
        resolution: String,
        details: String? = nil,
        underlying: Error? = nil
    ) -> String {
        let timestamp = makeDateFormatter().string(from: Date())
        let suffix = UUID().uuidString.prefix(8)
        let errorId = "ERR-\(timestamp)-\(suffix)"
        var detailParts: [String] = []
        if let details = details, !details.isEmpty {
            detailParts.append(details)
        }
        if let underlying = underlying {
            detailParts.append(underlying.localizedDescription)
        }
        let detailText = detailParts.isEmpty ? "No additional details are available." : detailParts.joined(separator: "; ")
        
        logger.error(
            "ErrorID: \(errorId, privacy: .public) | Type: \(errorType, privacy: .public) | Resolution: \(resolution, privacy: .public) | Details: \(detailText, privacy: .public)"
        )
        
        return """
        Error ID: \(errorId)
        Error Type: \(errorType)
        Resolution: \(resolution)
        Details: \(detailText)
        """
    }
}
