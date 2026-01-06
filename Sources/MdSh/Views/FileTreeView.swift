import SwiftUI

struct FileTreeView: View {
    let rootURL: URL
    @Environment(AppState.self) private var appState

    @State private var rootItems: [FileItem] = []
    @State private var isLoading = true
    @State private var showFilterPopover = false
    @State private var treeSelection: URL?
    @State private var directoryWatcher: DirectoryWatcher?

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
            loadRootItems()
            startDirectoryWatcher()
        }
        .onChange(of: rootURL) { _, _ in
            loadRootItems()
            startDirectoryWatcher()
        }
        .onChange(of: appState.enabledExtensions) { _, _ in
            reloadTree()
        }
        .onChange(of: appState.treeRefreshTrigger) { _, _ in
            reloadTree()
        }
        .onDisappear {
            stopDirectoryWatcher()
        }
    }

    private func startDirectoryWatcher() {
        stopDirectoryWatcher()
        let state = appState
        let url = rootURL
        directoryWatcher = DirectoryWatcher(url: url) {
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

    private func loadRootItems() {
        isLoading = true
        rootItems = FileScanner.shared.scanDirectory(rootURL, enabledExtensions: appState.enabledExtensions)
        // Pre-load children for root directories to ensure they display correctly
        for item in rootItems where item.isDirectory {
            loadChildrenRecursively(item, depth: 2)
        }
        isLoading = false
    }

    private func loadChildrenRecursively(_ item: FileItem, depth: Int) {
        guard depth > 0, item.isDirectory, !item.isLoaded else { return }
        FileScanner.shared.loadChildren(for: item, enabledExtensions: appState.enabledExtensions)
        if let children = item.children {
            for child in children where child.isDirectory {
                loadChildrenRecursively(child, depth: depth - 1)
            }
        }
    }

    private func reloadTree() {
        loadRootItems()
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

    var body: some View {
        Label {
            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            Image(systemName: item.iconName)
                .foregroundStyle(item.iconColor)
        }
    }
}
