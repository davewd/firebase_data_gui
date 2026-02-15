import Foundation
import os

struct ErrorReporter {
    private static let logger = Logger(subsystem: "FirebaseDataGUI", category: "Errors")
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter
    }()
    private static let formatterQueue = DispatchQueue(label: "FirebaseDataGUI.ErrorReporter.DateFormatter")
    private static let commandLineQueue = DispatchQueue(label: "FirebaseDataGUI.ErrorReporter.CommandLine")

    static func logError(_ message: String, logger: Logger? = nil) {
        let activeLogger = logger ?? self.logger
        activeLogger.error("\(message, privacy: .public)")
        printToCommandLine(message)
    }
    
    static func userMessage(
        errorType: String,
        resolution: String,
        details: String? = nil,
        underlying: Error? = nil
    ) -> String {
        let timestamp = formatterQueue.sync {
            dateFormatter.string(from: Date())
        }
        let shortUuid = String(UUID().uuidString.prefix(8))
        let errorId = "ERR-\(timestamp)-\(shortUuid)"
        var detailParts: [String] = []
        if let details = details, !details.isEmpty {
            detailParts.append(details)
        }
        if let underlying = underlying {
            detailParts.append(underlying.localizedDescription)
        }
        let detailText = detailParts.isEmpty ? "No additional details are available." : detailParts.joined(separator: "; ")
        
        let logMessage = "ErrorID: \(errorId) | Type: \(errorType) | Resolution: \(resolution) | Details: \(detailText)"
        logError(logMessage)
        
        return """
        Error ID: \(errorId)
        Error Type: \(errorType)
        Resolution: \(resolution)
        Details: \(detailText)
        """
    }

    private static func printToCommandLine(_ message: String) {
        let data = Data((message + "\n").utf8)
        commandLineQueue.sync {
            FileHandle.standardError.write(data)
        }
    }
}
