import SwiftUI
import MdShCore

@main
struct MdShApp: App {
    @FocusedValue(\.appState) private var focusedAppState
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            MainWindowView()
        }
        .defaultSize(width: 1200, height: 800)
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
        .windowResizability(.contentMinSize)

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
