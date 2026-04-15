import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                OCRView()
            }
            .tabItem {
                Label("OCR", systemImage: "doc.viewfinder")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label("Review", systemImage: "bookmark")
            }

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Label("My Page", systemImage: "person.fill")
            }
        }
        .tint(Color.blue)
    }
}
