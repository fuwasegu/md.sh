import Foundation
import CoreServices

/// Wrapper class to safely pass context to FSEvents callback
/// This allows us to invalidate the reference before the watcher is deallocated
private final class WatcherContext {
    weak var watcher: DirectoryWatcher?

    init(watcher: DirectoryWatcher) {
        self.watcher = watcher
    }
}

/// Watches a directory tree for file system changes using FSEvents
@MainActor
final class DirectoryWatcher {
    private let url: URL
    private let onChange: @MainActor ([URL]) -> Void
    private let debounceInterval: TimeInterval

    nonisolated(unsafe) private var eventStream: FSEventStreamRef?
    private var debounceTask: Task<Void, Never>?
    private var pendingChanges: Set<URL> = []

    // Context wrapper - must be retained as long as stream is active
    nonisolated(unsafe) private var contextRef: Unmanaged<WatcherContext>?

    init(url: URL, debounceInterval: TimeInterval = 0.5, onChange: @escaping @MainActor ([URL]) -> Void) {
        self.url = url
        self.onChange = onChange
        self.debounceInterval = debounceInterval
    }

    deinit {
        // Ensure cleanup if deallocated without explicit stop
        // Note: deinit is nonisolated, so we directly access nonisolated(unsafe) properties
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        if let ref = contextRef {
            ref.takeUnretainedValue().watcher = nil
            ref.release()
        }
    }

    func start() {
        stop()

        // Create context wrapper with retained reference
        let context = WatcherContext(watcher: self)
        contextRef = Unmanaged.passRetained(context)

        var fsContext = FSEventStreamContext()
        fsContext.info = contextRef?.toOpaque()

        let paths = [url.path as CFString] as CFArray

        eventStream = FSEventStreamCreate(
            nil,
            { _, info, numEvents, eventPaths, eventFlags, _ in
                guard let info = info else { return }
                // Get the context wrapper (not taking ownership)
                let contextWrapper = Unmanaged<WatcherContext>.fromOpaque(info).takeUnretainedValue()

                // Check if watcher is still valid (weak reference)
                guard let watcher = contextWrapper.watcher else { return }

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
            &fsContext,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )

        guard let stream = eventStream else {
            // Release context if stream creation failed
            contextRef?.release()
            contextRef = nil
            return
        }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        pendingChanges.removeAll()

        cleanupStream()
    }

    private func cleanupStream() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }

        // Release the context wrapper (must be done after stream is released)
        if let ref = contextRef {
            // Invalidate the weak reference first
            ref.takeUnretainedValue().watcher = nil
            ref.release()
            contextRef = nil
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
