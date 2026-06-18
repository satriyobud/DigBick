import Foundation

class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    func start() {
        // Open file descriptor for watching
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }

        // Create a dispatch source to watch for vnode events
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .delete, .rename],
            queue: DispatchQueue.global()
        )

        source?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            // If the file was deleted or renamed, we might need to recreate the watcher
            // For simple MVP, just trigger onChange
            self.onChange()
            
            // If deleted/renamed, we need to re-attach to the new file at the same path
            // Usually editors save by writing to a temp file and swapping, which triggers delete/rename.
            // We should stop and restart watching.
            let events = self.source?.data.rawValue ?? 0
            if (events & DispatchSource.FileSystemEvent.delete.rawValue) != 0 ||
               (events & DispatchSource.FileSystemEvent.rename.rawValue) != 0 {
                self.reconnect()
            }
        }

        source?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        source?.resume()
    }
    
    private func reconnect() {
        stop()
        // Wait a tiny bit for the editor to finish writing
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.start()
            self?.onChange()
        }
    }

    func stop() {
        if let src = source {
            src.cancel()
            source = nil
        }
    }

    deinit {
        stop()
    }
}
