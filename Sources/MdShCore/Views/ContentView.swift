import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showReviewPanel = false
    @State private var showTerminal = true

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Left: File Tree
            if let rootURL = appState.rootURL {
                FileTreeView(rootURL: rootURL)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Open a folder to get started")
                        .foregroundStyle(.secondary)
                    Button("Open Folder...") {
                        openFolder()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            // Center + Right: Preview | Terminal
            HSplitView {
                // Center: Tabs + Preview
                VStack(spacing: 0) {
                    if !appState.openTabs.isEmpty {
                        TabBarView()
                    }

                    if let tabID = appState.activeTabID,
                       let tab = appState.openTabs.first(where: { $0.id == tabID }) {
                        MarkdownPreviewView(fileURL: tab.url)
                            .id(tabID) // Force view recreation on tab switch
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Select a file to preview")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 300)

                // Right: Terminal (when visible)
                if showTerminal {
                    TerminalContainerView(workingDirectory: appState.rootURL)
                        .frame(minWidth: 250, idealWidth: 400)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            showTerminal.toggle()
                        }
                    } label: {
                        Label(
                            "Terminal",
                            systemImage: showTerminal
                                ? "terminal.fill"
                                : "terminal"
                        )
                    }
                    .help("Toggle Terminal (Cmd+T)")
                    .keyboardShortcut("t", modifiers: .command)

                    Button {
                        showReviewPanel.toggle()
                    } label: {
                        Label(
                            "Review",
                            systemImage: showReviewPanel
                                ? "text.bubble.fill"
                                : "text.bubble"
                        )
                    }
                    .help("Toggle Review Panel")
                }
            }
        }
        .inspector(isPresented: $showReviewPanel) {
            ReviewPanel()
                .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            appState.rootURL = url
        }
    }
}

// MARK: - Tab Bar

struct TabBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(appState.openTabs) { tab in
                TabButton(tab: tab)
            }
            Spacer()
        }
        .frame(height: 28)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct TabButton: View {
    let tab: TabItem
    @Environment(AppState.self) private var appState
    @State private var isHovering = false

    private var isActive: Bool {
        tab.id == appState.activeTabID
    }

    private var isModified: Bool {
        appState.isFileModified(tab.url)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main tab area - select button
            Button {
                appState.activeTabID = tab.id
                // Clear modified flag when tab is clicked
                appState.modifiedFiles.remove(tab.url)
            } label: {
                HStack(spacing: 4) {
                    Text(tab.name)
                        .lineLimit(1)
                    if isModified {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 4)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // Close button (visible on hover or when active)
            Button {
                appState.closeTab(tab)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.borderless)
            .opacity(isHovering || isActive ? 1 : 0)
            .padding(.trailing, 8)
        }
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
