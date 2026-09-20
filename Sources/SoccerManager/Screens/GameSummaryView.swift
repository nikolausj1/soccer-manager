import SwiftUI
import SwiftData
import SoccerManagerCore

/// Per-player totals for one game: field minutes, goal minutes, and goal
/// stints, sorted by field minutes descending. Reached after End Game and
/// by tapping a past game from the Game tab's list.
struct GameSummaryView: View {
    let game: GameRecord
    @Query private var allPlayers: [PlayerRecord]

    var body: some View {
        let names = Dictionary(uniqueKeysWithValues: allPlayers.map { ($0.id, $0.name) })
        let snapshot = GameEngine.snapshot(
            events: game.events.map(\.event),
            attendance: game.attendance,
            now: game.endedAt ?? .now
        )
        let rows = game.attendance
            .map { id in (id, snapshot.stats[id] ?? PlayerStats()) }
            .sorted { $0.1.fieldSeconds > $1.1.fieldSeconds }

        List {
            Section {
                ForEach(rows, id: \.0) { id, stats in
                    HStack {
                        Text(names[id] ?? "Unknown")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(formatMinutes(stats.fieldSeconds))
                            .frame(width: 56, alignment: .trailing)
                        Text(formatMinutes(stats.keeperSeconds))
                            .frame(width: 56, alignment: .trailing)
                        Text("\(stats.keeperStints)")
                            .frame(width: 60, alignment: .trailing)
                    }
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            } header: {
                HStack {
                    Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Field").frame(width: 56, alignment: .trailing)
                    Text("Goal").frame(width: 56, alignment: .trailing)
                    Text("Stints").frame(width: 60, alignment: .trailing)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .listStyle(.plain)
        .navigationTitle(game.createdAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GameSummaryView(game: GameRecord(attendance: []))
    }
    .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
