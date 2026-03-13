import SwiftUI

@main
struct FashionApp: App {
    // We remove 'private' here to ensure the state is managed
    // correctly at the top level of the app.
    @StateObject var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // This 'injects' your AppStore into every view in the app
                // so Onboarding, Outfit, and Closet all share the same data.
                .environmentObject(store)
        }
    }
}
