import SwiftUI
import SwiftData

@main
struct SoccerManagerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self])
    }
}
