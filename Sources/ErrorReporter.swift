import Foundation
import os

struct ErrorReporter {
    private static let logger = Logger(subsystem: "FirebaseDataGUI", category: "Errors")
    
    static func userMessage(
        errorType: String,
        resolution: String,
        details: String? = nil,
        underlying: Error? = nil
    ) -> String {
        let errorId = "ERR-\(UUID().uuidString.prefix(8))"
        var detailParts: [String] = []
        if let details = details, !details.isEmpty {
            detailParts.append(details)
        }
        if let underlying = underlying {
            detailParts.append(underlying.localizedDescription)
        }
        let detailText = detailParts.isEmpty ? "See logs for additional details." : detailParts.joined(separator: " | ")
        
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
