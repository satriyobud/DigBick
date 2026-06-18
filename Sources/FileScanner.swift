import Foundation

class FileScanner {
    static let shared = FileScanner()
    
    private let ignoredFolders: Set<String> = [
        ".git", "node_modules", ".next", "dist", "build", 
        "DerivedData", ".swiftpm", "Pods", "vendor", "coverage"
    ]
    
    private let validExtensions: Set<String> = [
        "md", "markdown", "mdown"
    ]
    
    func scan(workspaceURL: URL, completion: @escaping ([FileNode]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let nodes = self.scanDirectory(url: workspaceURL)
            DispatchQueue.main.async {
                completion(nodes)
            }
        }
    }
    
    private func scanDirectory(url: URL) -> [FileNode] {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        var files: [FileNode] = []
        var folders: [FileNode] = []
        
        for item in contents {
            let name = item.lastPathComponent
            
            guard let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory else { continue }
            
            if isDirectory {
                if ignoredFolders.contains(name) { continue }
                
                let children = scanDirectory(url: item)
                // Only add folder if it contains markdown files inside
                if !children.isEmpty {
                    folders.append(FileNode(url: item, isDirectory: true, children: children))
                }
            } else {
                let ext = item.pathExtension.lowercased()
                if validExtensions.contains(ext) {
                    files.append(FileNode(url: item, isDirectory: false))
                }
            }
        }
        
        // Sort folders first, then files alphabetically
        folders.sort { $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending }
        files.sort { $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending }
        
        return folders + files
    }
}
