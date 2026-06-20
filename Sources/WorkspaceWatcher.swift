import Foundation

/// Watches a workspace directory tree recursively using FSEvents.
/// Debounces rapid bursts (e.g. git checkout, npm install) into a single callback.
class WorkspaceWatcher {
    private let path: String
    private let onChange: () -> Void
    private var stream: FSEventStreamRef?
    private var debounceItem: DispatchWorkItem?

    private let debounceDelay: TimeInterval = 1.2  // seconds after last event

    private let ignoredNames: Set<String> = [
        ".git", "node_modules", ".next", "dist", "build",
        "DerivedData", ".swiftpm", "Pods", "vendor", "coverage",
        ".DS_Store"
    ]

    init(path: String, onChange: @escaping () -> Void) {
        self.path = path
        self.onChange = onChange
    }

    func start() {
        stop()

        var ctx = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, clientCallBackInfo, numEvents, eventPaths, _, _ in
            guard let info = clientCallBackInfo else { return }
            let watcher = Unmanaged<WorkspaceWatcher>.fromOpaque(info).takeUnretainedValue()

            // Filter: ignore events in ignored folders
            guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
            let relevant = paths.prefix(Int(numEvents)).contains { path in
                let components = path.components(separatedBy: "/")
                return !components.contains(where: { watcher.ignoredNames.contains($0) })
            }
            guard relevant else { return }

            watcher.scheduleCallback()
        }

        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &ctx,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,                                // latency: coalesce events within 0.5s
            FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagUseCFTypes |
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagNoDefer
            )
        )

        if let stream = stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }

    func stop() {
        debounceItem?.cancel()
        debounceItem = nil
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    private func scheduleCallback() {
        debounceItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async { self?.onChange() }
        }
        debounceItem = item
        DispatchQueue.global().asyncAfter(deadline: .now() + debounceDelay, execute: item)
    }

    deinit { stop() }
}
