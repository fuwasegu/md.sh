import Foundation

struct ReviewComment: Identifiable {
    let id = UUID()
    let fileURL: URL
    let startLine: Int
    let endLine: Int
    let originalText: String
    var comment: String
    let createdAt: Date = Date()

    var fileName: String {
        fileURL.lastPathComponent
    }

    var lineRange: String {
        if startLine == endLine {
            return "L\(startLine)"
        } else {
            return "L\(startLine)-\(endLine)"
        }
    }
}

@Observable
@MainActor
final class ReviewStore {
    var comments: [ReviewComment] = []

    func add(fileURL: URL, startLine: Int, endLine: Int, originalText: String, comment: String) {
        let review = ReviewComment(
            fileURL: fileURL,
            startLine: startLine,
            endLine: endLine,
            originalText: originalText,
            comment: comment
        )
        comments.append(review)
    }

    func remove(_ comment: ReviewComment) {
        comments.removeAll { $0.id == comment.id }
    }

    func update(_ comment: ReviewComment, newText: String) {
        if let index = comments.firstIndex(where: { $0.id == comment.id }) {
            comments[index].comment = newText
        }
    }

    func clear() {
        comments.removeAll()
    }

    func copyToClipboard() {
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

import AppKit
