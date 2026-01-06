import SwiftUI

@main
struct MdShApp: App {
    @FocusedValue(\.appState) private var focusedAppState
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            MainWindowView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Folder...") {
                    openFolderInCurrentWindow()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open Folder in New Window...") {
                    openFolderInNewWindow()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()

                Button("New Window") {
                    openWindow(id: "main")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }

    private func openFolderInCurrentWindow() {
        guard let url = showOpenPanel() else { return }
        focusedAppState?.rootURL = url
    }

    private func openFolderInNewWindow() {
        guard let url = showOpenPanel() else { return }
        // Store the URL to be picked up by the new window
        PendingProjectURL.shared.url = url
        openWindow(id: "main")
    }

    private func showOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            return panel.url
        }
        return nil
    }
}

// Shared storage for passing URL to new window
@MainActor
final class PendingProjectURL {
    static let shared = PendingProjectURL()
    var url: URL?

    func consume() -> URL? {
        let result = url
        url = nil
        return result
    }
}

// Main window view that creates its own AppState
struct MainWindowView: View {
    @State private var appState = AppState()

    var body: some View {
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
struct AppStateFocusedKey: FocusedValueKey {
    typealias Value = AppState
}

extension FocusedValues {
    var appState: AppState? {
        get { self[AppStateFocusedKey.self] }
        set { self[AppStateFocusedKey.self] = newValue }
    }
}

@MainActor
@Observable
final class AppState {
    var rootURL: URL? {
        didSet {
            if rootURL != oldValue {
                refreshExtensions()
                // Clear tabs when changing project
                openTabs = []
                activeTabID = nil
            }
        }
    }
    var reviewStore = ReviewStore()

    // Comment focus for highlighting in ReviewPanel
    var focusedCommentId: UUID?

    // Track files modified during this session (by external tools like Claude)
    var modifiedFiles: Set<URL> = []

    func markFileModified(_ url: URL) {
        modifiedFiles.insert(url)
    }

    func markFilesModified(_ urls: [URL]) {
        modifiedFiles.formUnion(urls)
    }

    func isFileModified(_ url: URL) -> Bool {
        modifiedFiles.contains(url)
    }

    // Terminal input handler
    var terminalSendHandler: ((String) -> Void)?

    func sendToTerminal(_ text: String) {
        terminalSendHandler?(text)
    }

    // Tab management
    var openTabs: [TabItem] = []
    var activeTabID: UUID?

    var activeTab: TabItem? {
        guard let id = activeTabID else { return nil }
        return openTabs.first { $0.id == id }
    }

    var selectedFile: URL? {
        activeTab?.url
    }

    func openFile(_ url: URL) {
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

    func closeTab(_ tab: TabItem) {
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

    func closeOtherTabs(_ tab: TabItem) {
        openTabs = openTabs.filter { $0.id == tab.id }
        activeTabID = tab.id
    }

    func closeAllTabs() {
        openTabs = []
        activeTabID = nil
    }

    // Extension filter
    var availableExtensions: [String] = []
    var enabledExtensions: Set<String> = []

    // Trigger for forcing tree refresh
    var treeRefreshTrigger: Int = 0

    func refreshExtensions() {
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

    func toggleExtension(_ ext: String) {
        if enabledExtensions.contains(ext) {
            enabledExtensions.remove(ext)
        } else {
            enabledExtensions.insert(ext)
        }
    }

    func enableAllExtensions() {
        enabledExtensions = Set(availableExtensions)
    }

    func disableAllExtensions() {
        enabledExtensions = []
    }
}

struct TabItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    var name: String {
        url.lastPathComponent
    }
}
