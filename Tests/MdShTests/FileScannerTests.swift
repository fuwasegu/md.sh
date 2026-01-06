import XCTest
import Foundation
@testable import MdShCore

@MainActor
final class FileScannerTests: XCTestCase {
    var testDirectory: URL!

    override func setUp() async throws {
        // Create a temporary test directory structure
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)

        // Create test files and directories
        // testDirectory/
        //   file1.md
        //   file2.txt
        //   subdir/
        //     file3.md
        //     file4.json

        try "# Test".write(to: testDirectory.appendingPathComponent("file1.md"), atomically: true, encoding: .utf8)
        try "Hello".write(to: testDirectory.appendingPathComponent("file2.txt"), atomically: true, encoding: .utf8)

        let subdir = testDirectory.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        try "# Nested".write(to: subdir.appendingPathComponent("file3.md"), atomically: true, encoding: .utf8)
        try "{}".write(to: subdir.appendingPathComponent("file4.json"), atomically: true, encoding: .utf8)

        // Clear any existing cache
        FileScanner.shared.clearCache()
    }

    override func tearDown() async throws {
        // Clean up test directory
        if let dir = testDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        FileScanner.shared.clearCache()
    }

    func testCollectExtensions() {
        let extensions = FileScanner.shared.collectExtensions(in: testDirectory)

        XCTAssertTrue(extensions.contains("md"))
        XCTAssertTrue(extensions.contains("txt"))
        XCTAssertTrue(extensions.contains("json"))
    }

    func testScanDirectoryWithFilter() {
        // First collect extensions to populate cache
        _ = FileScanner.shared.collectExtensions(in: testDirectory)

        // Scan with only .md enabled
        let mdItems = FileScanner.shared.scanDirectory(testDirectory, enabledExtensions: ["md"])

        // Should include file1.md and subdir (because it contains file3.md)
        let fileNames = mdItems.filter { !$0.isDirectory }.map(\.name)
        let dirNames = mdItems.filter(\.isDirectory).map(\.name)

        XCTAssertTrue(fileNames.contains("file1.md"))
        XCTAssertFalse(fileNames.contains("file2.txt"))
        XCTAssertTrue(dirNames.contains("subdir"))
    }

    func testScanDirectoryWithMultipleFilters() {
        _ = FileScanner.shared.collectExtensions(in: testDirectory)

        // Scan with .md and .json enabled
        let items = FileScanner.shared.scanDirectory(testDirectory, enabledExtensions: ["md", "json"])

        let fileNames = items.filter { !$0.isDirectory }.map(\.name)
        XCTAssertTrue(fileNames.contains("file1.md"))
        XCTAssertFalse(fileNames.contains("file2.txt"))
    }

    func testCacheClearing() {
        // Collect extensions for one directory
        _ = FileScanner.shared.collectExtensions(in: testDirectory)

        // Create a new directory
        let newDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: true)
        try! "test".write(to: newDir.appendingPathComponent("test.yaml"), atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: newDir) }

        // Collect extensions for the new directory (should clear cache)
        let newExtensions = FileScanner.shared.collectExtensions(in: newDir)

        XCTAssertTrue(newExtensions.contains("yaml"))
        XCTAssertFalse(newExtensions.contains("md")) // Should not contain old extensions
    }

    func testDirectorySorting() {
        _ = FileScanner.shared.collectExtensions(in: testDirectory)
        let items = FileScanner.shared.scanDirectory(testDirectory, enabledExtensions: ["md", "txt", "json"])

        // Directories should come before files
        if let firstDirIndex = items.firstIndex(where: \.isDirectory),
           let lastFileIndex = items.lastIndex(where: { !$0.isDirectory }) {
            XCTAssertLessThan(firstDirIndex, lastFileIndex)
        }
    }

    func testLoadChildren() {
        _ = FileScanner.shared.collectExtensions(in: testDirectory)
        let items = FileScanner.shared.scanDirectory(testDirectory, enabledExtensions: ["md", "json"])

        // Find subdir
        guard let subdir = items.first(where: { $0.isDirectory && $0.name == "subdir" }) else {
            XCTFail("Subdir not found")
            return
        }

        XCTAssertFalse(subdir.isLoaded)

        // Load children
        FileScanner.shared.loadChildren(for: subdir, enabledExtensions: ["md", "json"])

        XCTAssertTrue(subdir.isLoaded)
        XCTAssertNotNil(subdir.children)
        XCTAssertEqual(subdir.children?.count, 2) // file3.md and file4.json
    }

    func testIgnoredDirectories() async throws {
        // Create a node_modules directory (should be ignored)
        let nodeModules = testDirectory.appendingPathComponent("node_modules")
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)
        try "module".write(to: nodeModules.appendingPathComponent("module.js"), atomically: true, encoding: .utf8)

        let extensions = FileScanner.shared.collectExtensions(in: testDirectory)

        // .js should not be in extensions (node_modules is ignored)
        XCTAssertFalse(extensions.contains("js"))
    }
}
