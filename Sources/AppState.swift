import Foundation
import SwiftUI
import AppKit

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

class AppState: ObservableObject {
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme")
            applyTheme(appTheme)
        }
    }

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
        let savedThemeRaw = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        let theme = AppTheme(rawValue: savedThemeRaw) ?? .system
        self.appTheme = theme
        self.sidebarWidth = Swift.max(220, Swift.min(480, UserDefaults.standard.object(forKey: "sidebarWidth") as? CGFloat ?? 280.0))
        self.hasUserResizedSidebar = UserDefaults.standard.bool(forKey: "hasUserResizedSidebar")
        applyTheme(theme)
    }
    
    private func applyTheme(_ theme: AppTheme) {
        DispatchQueue.main.async {
            switch theme {
            case .system:
                NSApp.appearance = nil
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
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

