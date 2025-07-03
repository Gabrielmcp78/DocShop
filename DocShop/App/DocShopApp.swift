import SwiftUI

@main
struct DocShopApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Apply glass/morph effect background
                Color.clear // fallback for unsupported OS
                    .background(.ultraThinMaterial)
                    // .morphEffect() // Uncomment if supported on your deployment target
                ContentView()
            }
        }
    }
}
