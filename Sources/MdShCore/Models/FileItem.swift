import Foundation
import SwiftUI

@MainActor
@Observable
final class FileItem: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let name: String
    let isDirectory: Bool

    var children: [FileItem]?
    var isLoaded: Bool = false

    init(url: URL, isDirectory: Bool) {
        self.id = url
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = isDirectory ? [] : nil
    }

    nonisolated static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        switch url.pathExtension.lowercased() {
        case "md", "markdown":
            return "doc.text"
        case "json":
            return "curlybraces"
        case "yaml", "yml":
            return "list.bullet.rectangle"
        case "mermaid":
            return "chart.bar.doc.horizontal"
        default:
            return "doc"
        }
    }

    var iconColor: Color {
        if isDirectory {
            return .blue
        }
        switch url.pathExtension.lowercased() {
        case "md", "markdown":
            return .orange
        case "json":
            return .yellow
        case "yaml", "yml":
            return .purple
        case "mermaid":
            return .green
        default:
            return .gray
        }
    }
}
