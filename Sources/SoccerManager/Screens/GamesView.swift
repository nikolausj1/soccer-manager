import SwiftUI
import SwiftData
import SoccerManagerCore

/// The Game tab: the live game when one is in progress, otherwise a list of
/// finished games newest first.
struct GamesView: View {
    @Query(sort: \GameRecord.createdAt, order: .reverse) private var games: [GameRecord]
    @Query(filter: #Predicate<PlayerRecord> { !$0.isArchived }) private var activePlayers: [PlayerRecord]

    @State private var isPresentingNewGame = false
    @State private var justFinishedGame: GameRecord?

    /// The most recently created game that is not yet finished, if any.
    /// `games` is already sorted newest first.
    private var liveGame: GameRecord? {
        games.first { !$0.isFinished }
    }

    private var finishedGames: [GameRecord] {
        games.filter(\.isFinished)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let liveGame {
                    LiveGameView(game: liveGame, onFinished: { justFinishedGame = $0 })
                } else if finishedGames.isEmpty {
                    ContentUnavailableView {
                        Label("No games yet", systemImage: "sportscourt")
                    } actions: {
                        Button("New Game") { isPresentingNewGame = true }
                            .disabled(activePlayers.isEmpty)
                    }
                } else {
                    List(finishedGames) { game in
                        NavigationLink {
                            GameSummaryView(game: game)
                        } label: {
                            GameRow(game: game)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(TeamConfig.name)
            .toolbar {
                if liveGame == nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("New Game") { isPresentingNewGame = true }
                            .disabled(activePlayers.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewGame) {
                NewGameSheet()
            }
            .navigationDestination(item: $justFinishedGame) { game in
                GameSummaryView(game: game)
            }
        }
    }
}

/// One row in the finished-games list: date, attendance count, total
/// minutes.
private struct GameRow: View {
    let game: GameRecord

    private var snapshot: GameSnapshot {
        GameEngine.snapshot(events: game.events.map(\.event), attendance: game.attendance, now: game.endedAt ?? .now)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(game.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Text("\(game.attendance.count) players")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatMinutes(snapshot.elapsedTotal))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GamesView()
        .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
