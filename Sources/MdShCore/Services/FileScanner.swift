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

    // Cache: directory URL -> set of extensions contained in that directory (recursively)
    private var directoryExtensionsCache: [URL: Set<String>] = [:]
    private var cachedRootURL: URL?

    /// Clear cache when switching projects
    func clearCache() {
        directoryExtensionsCache.removeAll()
        cachedRootURL = nil
    }

    /// Collect all unique file extensions in a directory (recursively)
    /// Also populates the directory extensions cache for fast filtering
    func collectExtensions(in directoryURL: URL) -> [String] {
        // Clear cache if root changed
        if cachedRootURL != directoryURL {
            clearCache()
            cachedRootURL = directoryURL
        }

        var allExtensions = Set<String>()
        // Map: directory -> extensions found directly in that directory
        var directExtensions: [URL: Set<String>] = [:]
        // Map: directory -> child directories
        var directoryChildren: [URL: [URL]] = [:]

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        // First pass: collect all files and build directory structure
        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent

            // Skip ignored directories
            if Self.ignoredDirectories.contains(name) {
                enumerator.skipDescendants()
                continue
            }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory else {
                continue
            }

            let parentURL = fileURL.deletingLastPathComponent()

            if isDirectory {
                // Track directory hierarchy
                directoryChildren[parentURL, default: []].append(fileURL)
            } else {
                let ext = fileURL.pathExtension.lowercased()
                if !ext.isEmpty {
                    allExtensions.insert(ext)
                    directExtensions[parentURL, default: []].insert(ext)
                }
            }
        }

        // Second pass: propagate extensions up the directory tree (bottom-up)
        // Build the cache by calculating what extensions each directory contains (including subdirs)
        func extensionsInDirectory(_ url: URL) -> Set<String> {
            if let cached = directoryExtensionsCache[url] {
                return cached
            }

            var extensions = directExtensions[url] ?? []
            for childDir in directoryChildren[url] ?? [] {
                extensions.formUnion(extensionsInDirectory(childDir))
            }

            directoryExtensionsCache[url] = extensions
            return extensions
        }

        // Populate cache for root and all directories
        _ = extensionsInDirectory(directoryURL)

        return Array(allExtensions)
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

                // Check if directory contains any enabled files (using cache)
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
        // Use cache if available (much faster)
        if let cachedExtensions = directoryExtensionsCache[directoryURL] {
            return !cachedExtensions.isDisjoint(with: enabledExtensions)
        }

        // Fallback to scanning if cache miss (shouldn't happen after collectExtensions)
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        var foundExtensions = Set<String>()

        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent

            // Skip ignored directories
            if Self.ignoredDirectories.contains(name) {
                enumerator.skipDescendants()
                continue
            }

            // Check if it's a file
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory else {
                continue
            }

            if !isDirectory {
                let ext = fileURL.pathExtension.lowercased()
                if !ext.isEmpty {
                    foundExtensions.insert(ext)
                    // Early exit if we find an enabled extension
                    if enabledExtensions.contains(ext) {
                        // Cache this result
                        directoryExtensionsCache[directoryURL] = foundExtensions
                        return true
                    }
                }
            }
        }

        // Cache the complete result
        directoryExtensionsCache[directoryURL] = foundExtensions
        return !foundExtensions.isDisjoint(with: enabledExtensions)
    }
}
