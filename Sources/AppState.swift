import Foundation

class AppState: ObservableObject {
    @Published var showFileSidebar: Bool = false
    @Published var showTOCSidebar: Bool = false
    
    @Published var isReadingMode: Bool = false
    @Published var activeHeadingId: String? = nil
    
    private var cachedFileSidebarState: Bool = false
    private var cachedTOCSidebarState: Bool = false
    
    func toggleReadingMode() {
        if isReadingMode {
            // Restore cached states
            showFileSidebar = cachedFileSidebarState
            showTOCSidebar = cachedTOCSidebarState
            isReadingMode = false
        } else {
            // Cache current states and enter Reading Mode
            cachedFileSidebarState = showFileSidebar
            cachedTOCSidebarState = showTOCSidebar
            
            showFileSidebar = false
            showTOCSidebar = false
            isReadingMode = true
        }
    }
}
