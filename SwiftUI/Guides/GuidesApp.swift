import SwiftUI

@main
struct GuidesApp: App {
    @StateObject private var appState = DittoApp(configuration: loadAppConfig())
    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Error", isPresented: Binding(
                    get: { appState.error != nil },
                    set: { if !$0 { appState.error = nil } }
                )) {
                    Button("OK", role: .cancel) {
                        appState.error = nil
                    }
                } message: {
                    Text(appState.error?.localizedDescription ?? "Unknown Error")
                }
                .environmentObject(appState)
        }
    }
}
