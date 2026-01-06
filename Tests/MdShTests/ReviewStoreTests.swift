import XCTest
import Foundation
@testable import MdShCore

@MainActor
final class ReviewStoreTests: XCTestCase {
    func testAddComment() {
        let store = ReviewStore()
        store.add(
            fileURL: URL(fileURLWithPath: "/test.md"),
            startLine: 1,
            endLine: 5,
            originalText: "original",
            comment: "my comment"
        )
        XCTAssertEqual(store.comments.count, 1)
        XCTAssertEqual(store.comments[0].comment, "my comment")
    }

    func testRemoveComment() {
        let store = ReviewStore()
        store.add(
            fileURL: URL(fileURLWithPath: "/test.md"),
            startLine: 1,
            endLine: 1,
            originalText: "text",
            comment: "comment"
        )
        let comment = store.comments[0]
        store.remove(comment)
        XCTAssertTrue(store.comments.isEmpty)
    }

    func testUpdateComment() {
        let store = ReviewStore()
        store.add(
            fileURL: URL(fileURLWithPath: "/test.md"),
            startLine: 1,
            endLine: 1,
            originalText: "text",
            comment: "original"
        )
        let comment = store.comments[0]
        store.update(comment, newText: "updated")
        XCTAssertEqual(store.comments[0].comment, "updated")
    }

    func testClearComments() {
        let store = ReviewStore()
        store.add(
            fileURL: URL(fileURLWithPath: "/test.md"),
            startLine: 1,
            endLine: 1,
            originalText: "text1",
            comment: "comment1"
        )
        store.add(
            fileURL: URL(fileURLWithPath: "/test.md"),
            startLine: 2,
            endLine: 2,
            originalText: "text2",
            comment: "comment2"
        )
        XCTAssertEqual(store.comments.count, 2)
        store.clear()
        XCTAssertTrue(store.comments.isEmpty)
    }
}
