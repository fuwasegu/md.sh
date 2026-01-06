import XCTest
import Foundation
@testable import MdShCore

@MainActor
final class FileItemTests: XCTestCase {
    func testFileItemCreation() {
        let url = URL(fileURLWithPath: "/test/file.md")
        let item = FileItem(url: url, isDirectory: false)

        XCTAssertEqual(item.url, url)
        XCTAssertEqual(item.name, "file.md")
        XCTAssertFalse(item.isDirectory)
        XCTAssertNil(item.children)
    }

    func testDirectoryItemCreation() {
        let url = URL(fileURLWithPath: "/test/folder")
        let item = FileItem(url: url, isDirectory: true)

        XCTAssertEqual(item.url, url)
        XCTAssertEqual(item.name, "folder")
        XCTAssertTrue(item.isDirectory)
        XCTAssertNotNil(item.children)
        XCTAssertEqual(item.children?.count, 0)
    }

    func testFileItemEquality() {
        let url = URL(fileURLWithPath: "/test/file.md")
        let item1 = FileItem(url: url, isDirectory: false)
        let item2 = FileItem(url: url, isDirectory: false)

        XCTAssertEqual(item1, item2)
    }

    func testFileItemIconForMarkdown() {
        let url = URL(fileURLWithPath: "/test/file.md")
        let item = FileItem(url: url, isDirectory: false)

        XCTAssertEqual(item.iconName, "doc.text")
    }

    func testFileItemIconForJSON() {
        let url = URL(fileURLWithPath: "/test/file.json")
        let item = FileItem(url: url, isDirectory: false)

        XCTAssertEqual(item.iconName, "curlybraces")
    }

    func testFileItemIconForYAML() {
        let url = URL(fileURLWithPath: "/test/file.yaml")
        let item = FileItem(url: url, isDirectory: false)

        XCTAssertEqual(item.iconName, "list.bullet.rectangle")
    }

    func testFileItemIconForMermaid() {
        let url = URL(fileURLWithPath: "/test/diagram.mermaid")
        let item = FileItem(url: url, isDirectory: false)

        XCTAssertEqual(item.iconName, "chart.bar.doc.horizontal")
    }

    func testFileItemIconForDirectory() {
        let url = URL(fileURLWithPath: "/test/folder")
        let item = FileItem(url: url, isDirectory: true)

        XCTAssertEqual(item.iconName, "folder.fill")
    }

    func testFileItemIconForUnknown() {
        let url = URL(fileURLWithPath: "/test/file.xyz")
        let item = FileItem(url: url, isDirectory: false)

        XCTAssertEqual(item.iconName, "doc")
    }

    func testIsDirectoryStatic() {
        let tempDir = FileManager.default.temporaryDirectory
        XCTAssertTrue(FileItem.isDirectory(tempDir))

        let fakeFile = tempDir.appendingPathComponent("nonexistent.txt")
        XCTAssertFalse(FileItem.isDirectory(fakeFile))
    }

    func testIsLoaded() {
        let url = URL(fileURLWithPath: "/test/folder")
        let item = FileItem(url: url, isDirectory: true)

        XCTAssertFalse(item.isLoaded)

        item.isLoaded = true
        XCTAssertTrue(item.isLoaded)
    }
}
