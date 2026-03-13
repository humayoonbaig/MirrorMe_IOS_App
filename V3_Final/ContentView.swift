import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @AppStorage("isFirstLaunchh") private var isFirstLaunch = true

    var body: some View {
        if isFirstLaunch {
            OnboardingView()
        } else {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)

                OutfitView(selectedTab: $selectedTab, previousTab: $previousTab)
                    .tabItem {
                        Label("Studio", systemImage: selectedTab == 1 ? "sparkles" : "sparkle")
                    }
                    .tag(1)

                ClosetView(selectedTab: $selectedTab, previousTab: $previousTab)
                    .tabItem {
                        Label("Closet", systemImage: selectedTab == 2 ? "cabinet.fill" : "cabinet")
                    }
                    .tag(2)

                CalendarView(selectedTab: $selectedTab, previousTab: $previousTab)
                    .tabItem {
                        Label("Plan", systemImage: selectedTab == 3 ? "calendar.badge.clock" : "calendar")
                    }
                    .tag(3)
            }
            .tint(.blue)
            .onChange(of: selectedTab) { oldValue, newValue in
                previousTab = oldValue
            }
            .onAppear {
                setupTabBarAppearance()
            }
        }
    }
    
    // MARK: - Glassmorphism Helper
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // This creates the semi-transparent glass effect
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // FIXED: Using titleTextAttributes instead of labelColor
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.accent
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.accent
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
