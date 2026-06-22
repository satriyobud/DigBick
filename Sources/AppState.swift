import Foundation

class AppState: ObservableObject {
    @Published var showFileSidebar: Bool = false
    @Published var showTOCSidebar: Bool = false
    
    @Published var isReadingMode: Bool = false
    @Published var activeHeadingId: String? = nil
    
    // Notifications
    @Published var copyToast: String? = nil
    
    // Search & Find States
    @Published var isQuickOpenVisible: Bool = false
    @Published var quickOpenQuery: String = ""
    @Published var sidebarSearchQuery: String = ""
    @Published var focusSidebarSearch: Bool = false
    
    @Published var isFindBarVisible: Bool = false
    @Published var findQuery: String = ""
    @Published var findMatchCount: Int = 0
    @Published var findCurrentIndex: Int = 0
    
    @Published var sidebarWidth: CGFloat {
        didSet {
            UserDefaults.standard.set(sidebarWidth, forKey: "sidebarWidth")
        }
    }
    
    @Published var hasUserResizedSidebar: Bool {
        didSet {
            UserDefaults.standard.set(hasUserResizedSidebar, forKey: "hasUserResizedSidebar")
        }
    }
    
    private var cachedFileSidebarState: Bool = false
    private var cachedTOCSidebarState: Bool = false
    
    init() {
        self.sidebarWidth = Swift.max(220, Swift.min(480, UserDefaults.standard.object(forKey: "sidebarWidth") as? CGFloat ?? 280.0))
        self.hasUserResizedSidebar = UserDefaults.standard.bool(forKey: "hasUserResizedSidebar")
    }
    
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

