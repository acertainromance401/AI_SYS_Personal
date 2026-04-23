import Foundation

@MainActor
final class AppRuntimeState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingSearchQuery: String?
}
