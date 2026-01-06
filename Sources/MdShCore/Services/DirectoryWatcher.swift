import Foundation
import CoreServices

/// Watches a directory tree for file system changes using FSEvents
@MainActor
final class DirectoryWatcher {
    private let url: URL
    private let onChange: @MainActor ([URL]) -> Void
    private let debounceInterval: TimeInterval

    private nonisolated(unsafe) var eventStream: FSEventStreamRef?
    private var debounceTask: Task<Void, Never>?
    private var pendingChanges: Set<URL> = []

    init(url: URL, debounceInterval: TimeInterval = 0.5, onChange: @escaping @MainActor ([URL]) -> Void) {
        self.url = url
        self.onChange = onChange
        self.debounceInterval = debounceInterval
    }

    deinit {
        // Ensure cleanup if deallocated without explicit stop
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }

    func start() {
        stop()

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let paths = [url.path as CFString] as CFArray

        eventStream = FSEventStreamCreate(
            nil,
            { (_, info, numEvents, eventPaths, eventFlags, _) in
                guard let info = info else { return }
                let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue()

                // Extract changed file paths
                var changedURLs: [URL] = []
                if let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] {
                    for i in 0..<numEvents {
                        let path = paths[i]
                        let flags = eventFlags[i]

                        // Only track file modifications and creations (not directories)
                        let isFile = (flags & UInt32(kFSEventStreamEventFlagItemIsFile)) != 0
                        let isModified = (flags & UInt32(kFSEventStreamEventFlagItemModified)) != 0
                        let isCreated = (flags & UInt32(kFSEventStreamEventFlagItemCreated)) != 0
                        let isRenamed = (flags & UInt32(kFSEventStreamEventFlagItemRenamed)) != 0

                        if isFile && (isModified || isCreated || isRenamed) {
                            changedURLs.append(URL(fileURLWithPath: path))
                        }
                    }
                }

                Task { @MainActor in
                    watcher.handleChange(changedURLs)
                }
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )

        guard let stream = eventStream else { return }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        pendingChanges.removeAll()

        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }

    private func handleChange(_ urls: [URL]) {
        // Accumulate changes
        pendingChanges.formUnion(urls)

        // Debounce rapid changes
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            guard let self = self else { return }
            let changes = Array(self.pendingChanges)
            self.pendingChanges.removeAll()
            self.onChange(changes)
        }
    }
}
