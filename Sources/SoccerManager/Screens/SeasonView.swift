import SwiftUI
import SwiftData
import SoccerManagerCore

/// Season-long totals per active player, sorted so the top row is whoever
/// is most due for a turn in goal: goal stints ascending, then goal minutes
/// ascending.
struct SeasonView: View {
    @Query(filter: #Predicate<GameRecord> { $0.isFinished })
    private var finishedGames: [GameRecord]
    @Query(filter: #Predicate<PlayerRecord> { !$0.isArchived }, sort: \PlayerRecord.sortOrder)
    private var activePlayers: [PlayerRecord]

    var body: some View {
        NavigationStack {
            Group {
                if finishedGames.isEmpty {
                    ContentUnavailableView("No finished games yet", systemImage: "chart.bar")
                } else {
                    let totals = SeasonTotals.compute(games: finishedGames.map {
                        SeasonGame(attendance: $0.attendance, events: $0.events.map(\.event), endedAt: $0.endedAt ?? $0.createdAt)
                    })
                    let rows = activePlayers
                        .map { player in (player, totals[player.id] ?? SeasonStats()) }
                        .sorted { a, b in
                            if a.1.keeperStints != b.1.keeperStints {
                                return a.1.keeperStints < b.1.keeperStints
                            }
                            return a.1.keeperSeconds < b.1.keeperSeconds
                        }

                    List {
                        Section {
                            ForEach(rows, id: \.0.id) { player, stats in
                                SeasonRow(name: player.name, stats: stats)
                            }
                        } header: {
                            HStack {
                                Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                                Text("GP").frame(width: 32, alignment: .trailing)
                                Text("Field").frame(width: 52, alignment: .trailing)
                                Text("Goal").frame(width: 52, alignment: .trailing)
                                Text("Stints").frame(width: 60, alignment: .trailing)
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Season")
        }
    }
}

/// One player's row in the season totals table.
private struct SeasonRow: View {
    let name: String
    let stats: SeasonStats

    var body: some View {
        HStack {
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(stats.gamesPlayed)")
                .frame(width: 32, alignment: .trailing)
            Text(formatMinutes(stats.fieldSeconds))
                .frame(width: 52, alignment: .trailing)
            Text(formatMinutes(stats.keeperSeconds))
                .frame(width: 52, alignment: .trailing)
            Text("\(stats.keeperStints)")
                .frame(width: 60, alignment: .trailing)
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

#Preview {
    SeasonView()
        .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
