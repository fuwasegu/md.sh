import SwiftUI

// Shared storage for passing URL to new window
@MainActor
public final class PendingProjectURL {
    public static let shared = PendingProjectURL()
    public var url: URL?

    public func consume() -> URL? {
        let result = url
        url = nil
        return result
    }

    private init() {}
}

// Main window view that creates its own AppState
public struct MainWindowView: View {
    @State private var appState = AppState()

    public init() {}

    public var body: some View {
        ContentView()
            .environment(appState)
            .focusedValue(\.appState, appState)
            .onAppear {
                // Check if there's a pending URL from "Open in New Window"
                if let pendingURL = PendingProjectURL.shared.consume() {
                    appState.rootURL = pendingURL
                }
            }
    }
}

// FocusedValue for accessing AppState from menu commands
public struct AppStateFocusedKey: FocusedValueKey {
    public typealias Value = AppState
}

public extension FocusedValues {
    var appState: AppState? {
        get { self[AppStateFocusedKey.self] }
        set { self[AppStateFocusedKey.self] = newValue }
    }
}

@MainActor
@Observable
public final class AppState {
    public var rootURL: URL? {
        didSet {
            if rootURL != oldValue {
                refreshExtensions()
                // Clear tabs when changing project
                openTabs = []
                activeTabID = nil
                // Clear modified files when changing project
                modifiedFiles = []
            }
        }
    }
    public var reviewStore = ReviewStore()

    // Comment focus for highlighting in ReviewPanel
    public var focusedCommentId: UUID?

    // Track files modified during this session (by external tools like Claude)
    public var modifiedFiles: Set<URL> = []

    public func markFileModified(_ url: URL) {
        modifiedFiles.insert(url)
    }

    public func markFilesModified(_ urls: [URL]) {
        modifiedFiles.formUnion(urls)
    }

    public func isFileModified(_ url: URL) -> Bool {
        modifiedFiles.contains(url)
    }

    // Terminal input handler
    public var terminalSendHandler: ((String) -> Void)?

    public func sendToTerminal(_ text: String) {
        terminalSendHandler?(text)
    }

    // Tab management
    public var openTabs: [TabItem] = []
    public var activeTabID: UUID?

    public var activeTab: TabItem? {
        guard let id = activeTabID else { return nil }
        return openTabs.first { $0.id == id }
    }

    public var selectedFile: URL? {
        activeTab?.url
    }

    public func openFile(_ url: URL) {
        // Clear modified flag when file is opened
        modifiedFiles.remove(url)

        // Check if already open
        if let existing = openTabs.first(where: { $0.url == url }) {
            activeTabID = existing.id
            return
        }
        // Add new tab
        let tab = TabItem(url: url)
        openTabs.append(tab)
        activeTabID = tab.id
    }

    public func closeTab(_ tab: TabItem) {
        guard let index = openTabs.firstIndex(where: { $0.id == tab.id }) else { return }
        openTabs.remove(at: index)

        // Update active tab
        if activeTabID == tab.id {
            if openTabs.isEmpty {
                activeTabID = nil
            } else {
                // Select nearby tab
                let newIndex = min(index, openTabs.count - 1)
                activeTabID = openTabs[newIndex].id
            }
        }
    }

    public func closeOtherTabs(_ tab: TabItem) {
        openTabs = openTabs.filter { $0.id == tab.id }
        activeTabID = tab.id
    }

    public func closeAllTabs() {
        openTabs = []
        activeTabID = nil
    }

    // Extension filter
    public var availableExtensions: [String] = []
    public var enabledExtensions: Set<String> = []

    // Trigger for forcing tree refresh
    public var treeRefreshTrigger: Int = 0

    public func refreshExtensions() {
        guard let url = rootURL else {
            availableExtensions = []
            enabledExtensions = []
            return
        }
        let newExtensions = FileScanner.shared.collectExtensions(in: url).sorted()

        // If first time (no extensions yet), enable all
        if availableExtensions.isEmpty {
            availableExtensions = newExtensions
            enabledExtensions = Set(newExtensions)
        } else {
            // Add new extensions to enabled set (preserve existing filter)
            let addedExtensions = Set(newExtensions).subtracting(availableExtensions)
            for ext in addedExtensions {
                enabledExtensions.insert(ext)
            }
            availableExtensions = newExtensions
        }

        // Always trigger tree refresh
        treeRefreshTrigger += 1
    }

    public func toggleExtension(_ ext: String) {
        if enabledExtensions.contains(ext) {
            enabledExtensions.remove(ext)
        } else {
            enabledExtensions.insert(ext)
        }
    }

    public func enableAllExtensions() {
        enabledExtensions = Set(availableExtensions)
    }

    public func disableAllExtensions() {
        enabledExtensions = []
    }

    public init() {}
}

public struct TabItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL

    public var name: String {
        url.lastPathComponent
    }

    public init(url: URL) {
        self.url = url
    }
}
