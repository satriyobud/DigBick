import SwiftUI

class AppState: ObservableObject {
    @AppStorage("showFileSidebar") var showFileSidebar: Bool = false
    @AppStorage("showTOCSidebar") var showTOCSidebar: Bool = false
}
