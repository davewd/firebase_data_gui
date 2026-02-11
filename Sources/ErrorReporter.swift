import Foundation
import os

struct ErrorReporter {
    private static let logger = Logger(subsystem: "FirebaseDataGUI", category: "Errors")
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
    
    static func userMessage(
        errorType: String,
        resolution: String,
        details: String? = nil,
        underlying: Error? = nil
    ) -> String {
        let rawTimestamp = dateFormatter.string(from: Date())
        let timestamp = rawTimestamp
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "T", with: "")
        let suffix = String(UUID().uuidString.prefix(8))
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
