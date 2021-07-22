import SwiftUI

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(vm: DirectionsViewModel())
            }
        }
    }
}
