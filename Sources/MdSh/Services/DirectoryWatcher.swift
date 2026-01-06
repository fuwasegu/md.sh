import Foundation
import CoreServices

/// Watches a directory tree for file system changes using FSEvents
@MainActor
final class DirectoryWatcher {
    private let url: URL
    private let onChange: @MainActor () -> Void
    private let debounceInterval: TimeInterval

    private nonisolated(unsafe) var eventStream: FSEventStreamRef?
    private var debounceTask: Task<Void, Never>?

    init(url: URL, debounceInterval: TimeInterval = 0.5, onChange: @escaping @MainActor () -> Void) {
        self.url = url
        self.onChange = onChange
        self.debounceInterval = debounceInterval
    }

    func start() {
        stop()

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let paths = [url.path as CFString] as CFArray

        eventStream = FSEventStreamCreate(
            nil,
            { (_, info, _, _, _, _) in
                guard let info = info else { return }
                let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
                Task { @MainActor in
                    watcher.handleChange()
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

        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }

    private func handleChange() {
        // Debounce rapid changes
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.onChange()
        }
    }
}
