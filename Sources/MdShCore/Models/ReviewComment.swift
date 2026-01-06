import AppKit
import Foundation

public struct ReviewComment: Identifiable {
    public let id = UUID()
    public let fileURL: URL
    public let startLine: Int
    public let endLine: Int
    public let originalText: String
    public var comment: String
    public let createdAt: Date = Date()

    public var fileName: String {
        fileURL.lastPathComponent
    }

    public var lineRange: String {
        if startLine == endLine {
            return "L\(startLine)"
        } else {
            return "L\(startLine)-\(endLine)"
        }
    }

    public init(fileURL: URL, startLine: Int, endLine: Int, originalText: String, comment: String) {
        self.fileURL = fileURL
        self.startLine = startLine
        self.endLine = endLine
        self.originalText = originalText
        self.comment = comment
    }
}

@Observable
@MainActor
public final class ReviewStore {
    public var comments: [ReviewComment] = []

    public init() {}

    public func add(fileURL: URL, startLine: Int, endLine: Int, originalText: String, comment: String) {
        let review = ReviewComment(
            fileURL: fileURL,
            startLine: startLine,
            endLine: endLine,
            originalText: originalText,
            comment: comment
        )
        comments.append(review)
    }

    public func remove(_ comment: ReviewComment) {
        comments.removeAll { $0.id == comment.id }
    }

    public func update(_ comment: ReviewComment, newText: String) {
        if let index = comments.firstIndex(where: { $0.id == comment.id }) {
            comments[index].comment = newText
        }
    }

    public func clear() {
        comments.removeAll()
    }

    public func copyToClipboard() {
        let text = formatForClipboard()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func formatForClipboard() -> String {
        guard !comments.isEmpty else { return "" }

        // Group by file
        let grouped = Dictionary(grouping: comments) { $0.fileName }

        var output = ""

        for (fileName, fileComments) in grouped.sorted(by: { $0.key < $1.key }) {
            output += "## \(fileName)\n\n"

            for comment in fileComments.sorted(by: { $0.startLine < $1.startLine }) {
                output += "### \(comment.lineRange)\n"
                // Quote original text
                let quoted = comment.originalText
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .map { "> \($0)" }
                    .joined(separator: "\n")
                output += "\(quoted)\n\n"
                output += "\(comment.comment)\n\n"
            }
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
