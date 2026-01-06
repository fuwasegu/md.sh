import SwiftUI

struct FileTreeView: View {
    let rootURL: URL
    @Environment(AppState.self) private var appState

    @State private var rootItems: [FileItem] = []
    @State private var isLoading = true
    @State private var showFilterPopover = false
    @State private var treeSelection: URL?
    @State private var directoryWatcher: DirectoryWatcher?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if rootItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No files match filter")
                        .foregroundStyle(.secondary)
                    if !appState.availableExtensions.isEmpty {
                        Button("Show All") {
                            appState.enableAllExtensions()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $treeSelection) {
                    OutlineGroup(rootItems, children: \.children) { item in
                        FileRowView(item: item)
                            .tag(item.url)
                            .onAppear {
                                if item.isDirectory && !item.isLoaded {
                                    FileScanner.shared.loadChildren(
                                        for: item,
                                        enabledExtensions: appState.enabledExtensions
                                    )
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
                .id(appState.treeRefreshTrigger)  // Force List rebuild
                .onChange(of: treeSelection) { _, newValue in
                    if let url = newValue, !FileItem.isDirectory(url) {
                        appState.openFile(url)
                    }
                }
            }
        }
        .navigationTitle(rootURL.lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showFilterPopover.toggle()
                } label: {
                    Label("Filter", systemImage: filterIconName)
                }
                .popover(isPresented: $showFilterPopover, arrowEdge: .bottom) {
                    ExtensionFilterView()
                        .frame(width: 200)
                }
                .help("Filter by file extension")
            }
        }
        .onAppear {
            loadRootItemsAsync()
            startDirectoryWatcher()
        }
        .onChange(of: rootURL) { _, _ in
            loadRootItemsAsync()
            startDirectoryWatcher()
        }
        .onChange(of: appState.enabledExtensions) { _, _ in
            reloadTreeAsync()
        }
        .onChange(of: appState.treeRefreshTrigger) { _, _ in
            reloadTreeAsync()
        }
        .onDisappear {
            loadTask?.cancel()
            stopDirectoryWatcher()
        }
    }

    private func startDirectoryWatcher() {
        stopDirectoryWatcher()
        let state = appState
        let url = rootURL
        directoryWatcher = DirectoryWatcher(url: url) { changedFiles in
            // Mark changed files as modified
            state.markFilesModified(changedFiles)
            // Refresh extensions (for new files)
            state.refreshExtensions()
        }
        directoryWatcher?.start()
    }

    private func stopDirectoryWatcher() {
        directoryWatcher?.stop()
        directoryWatcher = nil
    }

    private var filterIconName: String {
        let allEnabled = appState.enabledExtensions.count == appState.availableExtensions.count
        return allEnabled ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
    }

    private func loadRootItemsAsync() {
        // Cancel any existing load task
        loadTask?.cancel()

        isLoading = true

        loadTask = Task { @MainActor in
            // Small yield to let UI update with loading state
            await Task.yield()

            guard !Task.isCancelled else { return }

            let items = FileScanner.shared.scanDirectory(rootURL, enabledExtensions: appState.enabledExtensions)

            guard !Task.isCancelled else { return }

            // Pre-load children for root directories (depth 1 only)
            // This ensures disclosure indicators appear correctly
            for item in items where item.isDirectory {
                FileScanner.shared.loadChildren(for: item, enabledExtensions: appState.enabledExtensions)
            }

            guard !Task.isCancelled else { return }

            rootItems = items
            isLoading = false
        }
    }

    private func reloadTreeAsync() {
        loadRootItemsAsync()
    }
}

struct ExtensionFilterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Extensions")
                    .font(.headline)
                Spacer()
                Button("All") {
                    appState.enableAllExtensions()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                Button("None") {
                    appState.disableAllExtensions()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Divider()

            if appState.availableExtensions.isEmpty {
                Text("No files found")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(appState.availableExtensions, id: \.self) { ext in
                            ExtensionToggleRow(ext: ext)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.bottom, 8)
    }
}

struct ExtensionToggleRow: View {
    let ext: String
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.toggleExtension(ext)
        } label: {
            HStack {
                Image(systemName: appState.enabledExtensions.contains(ext) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(appState.enabledExtensions.contains(ext) ? .blue : .secondary)
                Text(".\(ext)")
                    .foregroundStyle(.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FileRowView: View {
    let item: FileItem
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 4) {
            Label {
                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } icon: {
                Image(systemName: item.iconName)
                    .foregroundStyle(item.iconColor)
            }

            if !item.isDirectory && appState.isFileModified(item.url) {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
