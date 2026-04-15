import SwiftUI

@main
struct AISYSApp: App {
    @StateObject private var store = ReviewStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
