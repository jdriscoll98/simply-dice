import SwiftUI

@main
struct SimplyDiceApp: App {
    @StateObject var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
