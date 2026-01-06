import XCTest
import Foundation
@testable import MdShCore

@MainActor
final class AppStateTests: XCTestCase {
    func testOpenFileCreatesTab() {
        let state = AppState()
        let url = URL(fileURLWithPath: "/test.md")
        state.openFile(url)

        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertNotNil(state.activeTabID)
        XCTAssertEqual(state.selectedFile, url)
    }

    func testOpenFileReusesExistingTab() {
        let state = AppState()
        let url = URL(fileURLWithPath: "/test.md")
        state.openFile(url)
        let firstTabID = state.activeTabID
        state.openFile(url)

        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertEqual(state.activeTabID, firstTabID)
    }

    func testCloseTab() {
        let state = AppState()
        let url1 = URL(fileURLWithPath: "/test1.md")
        let url2 = URL(fileURLWithPath: "/test2.md")
        state.openFile(url1)
        state.openFile(url2)

        let tab2 = state.openTabs[1]
        state.closeTab(tab2)

        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertEqual(state.selectedFile, url1)
    }

    func testCloseOtherTabs() {
        let state = AppState()
        state.openFile(URL(fileURLWithPath: "/test1.md"))
        state.openFile(URL(fileURLWithPath: "/test2.md"))
        state.openFile(URL(fileURLWithPath: "/test3.md"))

        let keepTab = state.openTabs[1]
        state.closeOtherTabs(keepTab)

        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertEqual(state.activeTabID, keepTab.id)
    }

    func testCloseAllTabs() {
        let state = AppState()
        state.openFile(URL(fileURLWithPath: "/test1.md"))
        state.openFile(URL(fileURLWithPath: "/test2.md"))

        state.closeAllTabs()

        XCTAssertTrue(state.openTabs.isEmpty)
        XCTAssertNil(state.activeTabID)
    }

    func testMarkFileModified() {
        let state = AppState()
        let url = URL(fileURLWithPath: "/test.md")

        XCTAssertFalse(state.isFileModified(url))
        state.markFileModified(url)
        XCTAssertTrue(state.isFileModified(url))
    }

    func testOpenFileClearsModifiedFlag() {
        let state = AppState()
        let url = URL(fileURLWithPath: "/test.md")

        state.markFileModified(url)
        XCTAssertTrue(state.isFileModified(url))

        state.openFile(url)
        XCTAssertFalse(state.isFileModified(url))
    }
}
