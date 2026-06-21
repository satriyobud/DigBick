import Foundation

// MARK: - Model

struct RecentEntry: Codable, Identifiable, Equatable {
    var id: String { path }
    let path: String
    let displayName: String
    var lastOpenedAt: Date

    init(url: URL, date: Date = .now) {
        self.path        = url.standardizedFileURL.path
        self.displayName = url.lastPathComponent
        self.lastOpenedAt = date
    }

    var url: URL { URL(fileURLWithPath: path) }

    /// Returns nil if the path no longer exists on disk.
    var isValid: Bool { FileManager.default.fileExists(atPath: path) }
}

// MARK: - Manager

class RecentsManager: ObservableObject {
    static let shared = RecentsManager()

    private let maxItems = 8
    private let workspacesKey = "recentWorkspaces"
    private let filesKey      = "recentFiles"

    @Published private(set) var workspaces: [RecentEntry] = []
    @Published private(set) var files:      [RecentEntry] = []

    private init() { load() }

    // MARK: Add

    func addWorkspace(_ url: URL) {
        workspaces = prepend(RecentEntry(url: url), to: workspaces)
        save()
    }

    func addFile(_ url: URL) {
        files = prepend(RecentEntry(url: url), to: files)
        save()
    }

    // MARK: Clear

    func clearAll() {
        workspaces = []
        files      = []
        save()
    }

    // MARK: Private helpers

    /// Move-to-top + dedup + max 8 + prune missing.
    private func prepend(_ entry: RecentEntry, to list: [RecentEntry]) -> [RecentEntry] {
        var updated = [entry] + list.filter { $0.path != entry.path }
        updated = updated.filter { $0.isValid }
        return Array(updated.prefix(maxItems))
    }

    // MARK: Persistence

    private func load() {
        workspaces = decode(from: workspacesKey)
        files      = decode(from: filesKey)
        // Prune stale paths on load
        workspaces = workspaces.filter { $0.isValid }
        files      = files.filter      { $0.isValid }
    }

    private func save() {
        encode(workspaces, to: workspacesKey)
        encode(files,      to: filesKey)
    }

    private func decode(from key: String) -> [RecentEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([RecentEntry].self, from: data)
        else { return [] }
        return decoded
    }

    private func encode(_ entries: [RecentEntry], to key: String) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
