import Foundation

class AppState: ObservableObject {
    @Published var showFileSidebar: Bool = false
    @Published var showTOCSidebar: Bool = false
    
    @Published var isReadingMode: Bool = false
    @Published var activeHeadingId: String? = nil
    
    // Search & Find States
    @Published var isQuickOpenVisible: Bool = false
    @Published var quickOpenQuery: String = ""
    @Published var sidebarSearchQuery: String = ""
    @Published var focusSidebarSearch: Bool = false
    
    @Published var isFindBarVisible: Bool = false
    @Published var findQuery: String = ""
    @Published var findMatchCount: Int = 0
    @Published var findCurrentIndex: Int = 0
    
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
            isQuickOpenVisible = false
            isFindBarVisible = false
            isReadingMode = true
        }
    }
}
