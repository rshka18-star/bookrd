import SwiftUI

@main
struct SpfiveReaderApp: App {
    @StateObject private var speech = SpeechManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(speech)
                .preferredColorScheme(.dark)
        }
    }
}
