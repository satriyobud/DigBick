import Foundation

struct HeadingNode: Identifiable, Equatable {
    let id: String
    let text: String
    let level: Int
}

struct ScrollEntry: Codable {
    let y: Double
    let updatedAt: Date
}

class FileNode: Identifiable, ObservableObject {
    let id: URL
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?
    
    init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.id = url
        self.url = url
        self.isDirectory = isDirectory
        self.children = children
    }
}
