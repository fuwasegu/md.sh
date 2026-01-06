import XCTest
import Foundation
@testable import MdShCore

final class TabItemTests: XCTestCase {
    func testNameReturnsFilename() {
        let tab = TabItem(url: URL(fileURLWithPath: "/path/to/document.md"))
        XCTAssertEqual(tab.name, "document.md")
    }

    func testEachTabHasUniqueId() {
        let tab1 = TabItem(url: URL(fileURLWithPath: "/test.md"))
        let tab2 = TabItem(url: URL(fileURLWithPath: "/test.md"))
        XCTAssertNotEqual(tab1.id, tab2.id)
    }
}
