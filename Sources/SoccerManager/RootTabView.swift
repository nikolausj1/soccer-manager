import SwiftUI
import SwiftData

/// The app's root: three tabs over the current or most recent game, season
/// totals, and the roster.
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @State private var didApplyLaunchArguments = false

    var body: some View {
        TabView {
            GamesView()
                .tabItem { Label("Game", systemImage: "sportscourt") }
            SeasonView()
                .tabItem { Label("Season", systemImage: "chart.bar") }
            RosterView()
                .tabItem { Label("Roster", systemImage: "person.3") }
        }
        .tint(Color.algeriaGreen)
        .onAppear {
            guard !didApplyLaunchArguments else { return }
            didApplyLaunchArguments = true
            LaunchArguments.apply(context: context)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
