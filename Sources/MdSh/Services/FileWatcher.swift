@preconcurrency import Foundation

@MainActor
final class FileWatcher {
    private let url: URL
    private let onChange: @MainActor () -> Void

    private var fileDescriptor: Int32 = -1
    private nonisolated(unsafe) var source: DispatchSourceFileSystemObject?

    init(url: URL, onChange: @escaping @MainActor () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    deinit {
        source?.cancel()
    }

    func start() {
        stop()

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename, .delete],
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.handleFileChange()
            }
        }

        source?.setCancelHandler { [fileDescriptor = self.fileDescriptor] in
            if fileDescriptor >= 0 {
                close(fileDescriptor)
            }
        }

        source?.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }

    private func handleFileChange() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            self?.onChange()
        }
    }
}
