import XCTest
import Foundation
@testable import MdShCore

final class ReviewCommentTests: XCTestCase {
    func testLineRangeSingleLine() {
        let comment = ReviewComment(
            fileURL: URL(fileURLWithPath: "/test.md"),
            startLine: 5,
            endLine: 5,
            originalText: "test",
            comment: "comment"
        )
        XCTAssertEqual(comment.lineRange, "L5")
    }

    func testLineRangeMultipleLines() {
        let comment = ReviewComment(
            fileURL: URL(fileURLWithPath: "/test.md"),
            startLine: 5,
            endLine: 10,
            originalText: "test",
            comment: "comment"
        )
        XCTAssertEqual(comment.lineRange, "L5-10")
    }

    func testFileName() {
        let comment = ReviewComment(
            fileURL: URL(fileURLWithPath: "/path/to/test.md"),
            startLine: 1,
            endLine: 1,
            originalText: "test",
            comment: "comment"
        )
        XCTAssertEqual(comment.fileName, "test.md")
    }
}
