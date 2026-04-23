import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var runtime: AppRuntimeState

    var body: some View {
        TabView(selection: $runtime.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                OCRView()
            }
            .tabItem {
                Label("OCR", systemImage: "doc.viewfinder")
            }
            .tag(1)

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(2)

            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label("Review", systemImage: "bookmark")
            }
            .tag(3)

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Label("My Page", systemImage: "person.fill")
            }
            .tag(4)
        }
        .tint(Color.blue)
    }
}
