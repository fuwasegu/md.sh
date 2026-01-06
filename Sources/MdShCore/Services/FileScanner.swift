import Foundation

@MainActor
final class FileScanner {
    static let shared = FileScanner()

    private static let ignoredDirectories: Set<String> = [
        "node_modules",
        ".git",
        ".next",
        ".nuxt",
        ".svelte-kit",
        "dist",
        "build",
        ".build",
        "DerivedData",
        ".cache",
        "__pycache__",
        ".venv",
        "venv",
        "vendor",
        "Pods",
        ".idea",
        ".vscode"
    ]

    private let fileManager = FileManager.default

    /// Collect all unique file extensions in a directory (recursively)
    func collectExtensions(in directoryURL: URL) -> [String] {
        var extensions = Set<String>()

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent

            // Skip ignored directories
            if Self.ignoredDirectories.contains(name) {
                enumerator.skipDescendants()
                continue
            }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory,
                  !isDirectory else {
                continue
            }

            let ext = fileURL.pathExtension.lowercased()
            if !ext.isEmpty {
                extensions.insert(ext)
            }
        }

        return Array(extensions)
    }

    func scanDirectory(_ url: URL, enabledExtensions: Set<String>) -> [FileItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var items: [FileItem] = []

        for itemURL in contents {
            guard let resourceValues = try? itemURL.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey]),
                  let isDirectory = resourceValues.isDirectory,
                  resourceValues.isHidden != true else {
                continue
            }

            let name = itemURL.lastPathComponent

            if isDirectory {
                // Skip ignored directories
                if Self.ignoredDirectories.contains(name) {
                    continue
                }

                // Check if directory contains any enabled files (recursively)
                if containsEnabledFiles(in: itemURL, enabledExtensions: enabledExtensions) {
                    items.append(FileItem(url: itemURL, isDirectory: true))
                }
            } else {
                // Only include enabled file types
                let ext = itemURL.pathExtension.lowercased()
                if enabledExtensions.contains(ext) {
                    items.append(FileItem(url: itemURL, isDirectory: false))
                }
            }
        }

        // Sort: directories first, then alphabetically
        return items.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func loadChildren(for item: FileItem, enabledExtensions: Set<String>) {
        guard item.isDirectory, !item.isLoaded else { return }

        let children = scanDirectory(item.url, enabledExtensions: enabledExtensions)
        item.children = children
        item.isLoaded = true
    }

    private func containsEnabledFiles(in directoryURL: URL, enabledExtensions: Set<String>) -> Bool {
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent

            // Skip ignored directories
            if Self.ignoredDirectories.contains(name) {
                enumerator.skipDescendants()
                continue
            }

            // Check if it's an enabled file
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory else {
                continue
            }

            if !isDirectory {
                let ext = fileURL.pathExtension.lowercased()
                if enabledExtensions.contains(ext) {
                    return true
                }
            }
        }

        return false
    }
}
