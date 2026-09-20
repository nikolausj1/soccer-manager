import SwiftUI
import SwiftData
import SoccerManagerCore

/// The Game tab: always the games list. An in-progress game, if any, is
/// this list's own top row rather than replacing the screen; tapping a row
/// pushes either `LiveGameView` (in progress) or `GameSummaryView`
/// (finished) onto this stack's own path.
struct GamesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GameRecord.createdAt, order: .reverse) private var games: [GameRecord]
    @Query(filter: #Predicate<PlayerRecord> { !$0.isArchived }) private var activePlayers: [PlayerRecord]

    @State private var isPresentingNewGame = false
    @State private var pendingDeleteGame: GameRecord?
    @State private var path: [GameDestination] = []
    @State private var didAutoPushLiveGame = false

    /// The most recently created game that is not yet finished, if any.
    /// `games` is already sorted newest first.
    private var liveGame: GameRecord? {
        games.first { !$0.isFinished }
    }

    private var finishedGames: [GameRecord] {
        games.filter(\.isFinished)
    }

    /// Every row this list shows: the in-progress game first (if any),
    /// then finished games newest first.
    private var rows: [GameRecord] {
        if let liveGame { return [liveGame] + finishedGames }
        return finishedGames
    }

    private func game(id: UUID) -> GameRecord? {
        games.first { $0.id == id }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if rows.isEmpty {
                    ContentUnavailableView {
                        Label("No games yet", systemImage: "sportscourt")
                    } actions: {
                        Button("New Game") { isPresentingNewGame = true }
                            .disabled(activePlayers.isEmpty)
                    }
                } else {
                    List(rows) { game in
                        row(for: game)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    pendingDeleteGame = game
                                }
                                .tint(.algeriaRed)
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
                NewGameSheet(onCreate: { newGame in pushLiveGame(newGame.id) })
            }
            .navigationDestination(for: GameDestination.self) { destination in
                switch destination {
                case .live(let id):
                    if let game = game(id: id) {
                        LiveGameView(game: game, onFinished: { finished in
                            path = [.summary(finished.id)]
                        })
                    }
                case .summary(let id):
                    if let game = game(id: id) {
                        GameSummaryView(game: game)
                    }
                }
            }
            // An `.alert`, not a `.confirmationDialog`: a confirmationDialog
            // renders as a floating card whose bottom row can land behind
            // the floating tab bar, while an alert is a centered modal
            // nothing else can cover.
            .alert(
                "Delete this game?",
                isPresented: Binding(
                    get: { pendingDeleteGame != nil },
                    set: { isPresented in if !isPresented { pendingDeleteGame = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let game = pendingDeleteGame {
                        GameStore(context: context).discard(game: game)
                    }
                    pendingDeleteGame = nil
                }
                Button("Cancel", role: .cancel) { pendingDeleteGame = nil }
            } message: {
                Text("Season totals will update.")
            }
        }
        .onAppear(perform: attemptAutoPush)
        .onChange(of: liveGame?.id) { _, _ in attemptAutoPush() }
    }

    @ViewBuilder
    private func row(for game: GameRecord) -> some View {
        if game.isFinished {
            NavigationLink(value: GameDestination.summary(game.id)) {
                GameRow(game: game)
            }
        } else {
            NavigationLink(value: GameDestination.live(game.id)) {
                InProgressGameRow(game: game)
            }
        }
    }

    /// Pushes the in-progress game once, the first time the Game tab
    /// appears with one already present and nothing else on the path.
    /// Reactive rather than a single onAppear check, because launch-arg
    /// seeding can still be inserting that game the moment this view's own
    /// onAppear fires; `pushLiveGame` itself no-ops if a manual push (from
    /// "New Game") already landed first.
    private func attemptAutoPush() {
        guard !didAutoPushLiveGame, path.isEmpty, let liveGame else { return }
        didAutoPushLiveGame = true
        pushLiveGame(liveGame.id)
    }

    /// Pushes a live game's id, unless it is already the top of the path.
    private func pushLiveGame(_ id: UUID) {
        guard path.last != .live(id) else { return }
        path.append(.live(id))
    }
}

/// The two screens `GamesView` can push: an in-progress game's Live
/// screen, or a finished game's Summary. Keyed by id rather than holding
/// the `GameRecord` itself, so the path stays simple `Hashable` value data.
private enum GameDestination: Hashable {
    case live(UUID)
    case summary(UUID)
}

/// The in-progress game's row: always first, labeled "In progress" with
/// its date and its current phase (Kickoff, 1st Half, Halftime, 2nd Half).
private struct InProgressGameRow: View {
    let game: GameRecord

    private var snapshot: GameSnapshot {
        GameEngine.snapshot(events: game.events.map(\.event), attendance: game.attendance, now: .now)
    }

    private var phase: GamePhase {
        GamePhase.current(events: game.events.map(\.event), snapshot: snapshot)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("In progress")
                    .font(.headline)
                    .foregroundStyle(Color.algeriaGreen)
                Text(game.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(phase.displayText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// One row in the finished-games list: date, score if recorded, attendance
/// count, total minutes.
private struct GameRow: View {
    let game: GameRecord

    private var snapshot: GameSnapshot {
        GameEngine.snapshot(events: game.events.map(\.event), attendance: game.attendance, now: game.endedAt ?? .now)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(game.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    if let ourScore = game.ourScore, let theirScore = game.theirScore {
                        Text("\(ourScore) - \(theirScore)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Color.algeriaGreen)
                    }
                }
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
