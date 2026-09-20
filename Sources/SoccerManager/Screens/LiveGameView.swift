import SwiftUI
import SwiftData
import SoccerManagerCore

/// What is currently selected on the Live screen, awaiting a second tap to
/// complete an action. Tapping the same target again deselects it; the
/// order two targets are tapped in never changes the resulting action.
enum Selection: Equatable {
    case player(UUID)
    case keeperSlot
    case emptySlot
    case benchHeader
}

/// The tap-tap substitution screen: clock, ranked field and bench, and
/// Undo. The only screen that mutates a game's event log directly.
///
/// Layout is three fixed regions, not one scrolling page: `ClockHeader` is
/// pinned above the scrolling field and bench lists, and Undo plus the End
/// Game footer sit in a bottom `safeAreaInset` above the tab bar. Only the
/// field and bench rows scroll. Field and bench rendering lives in
/// `LiveGameView+Sections.swift`; the bottom bar and its dialogs live in
/// `LiveGameView+Footer.swift`; the tap-resolution engine calls live in
/// `LiveGameView+Actions.swift`.
struct LiveGameView: View {
    let game: GameRecord
    var onFinished: (GameRecord) -> Void = { _ in }

    @Environment(\.modelContext) var context
    @Query var allPlayers: [PlayerRecord]

    @AppStorage(AppSettings.shiftLengthMinutesKey)
    var shiftLengthMinutes = AppSettings.defaultShiftLengthMinutes

    @State var selectedHalf = 1
    @State var selected: Selection?
    @State var showEndGameConfirm = false
    @State var showScoreSheet = false

    /// The moment "End and save" was tapped, captured so the game's
    /// recorded end time reflects that tap and not however long Justin
    /// spends on the score sheet. `finish(game:at:)` only actually runs
    /// once the sheet is dismissed (see `body`): flipping `isFinished`
    /// any earlier would make `GamesView` swap this view out of the
    /// hierarchy immediately, tearing down `showScoreSheet` before the
    /// sheet ever gets a chance to present.
    @State var pendingEndedAt: Date?

    var store: GameStore { GameStore(context: context) }

    /// The target shift length players are ranked against, for the
    /// readiness bars.
    var shiftLengthSeconds: TimeInterval { TimeInterval(shiftLengthMinutes * 60) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let snapshot = store.snapshot(for: game, now: timeline.date)
            let names = Dictionary(uniqueKeysWithValues: allPlayers.map { ($0.id, $0.name) })

            VStack(spacing: 0) {
                ClockHeader(
                    snapshot: snapshot,
                    selectedHalf: $selectedHalf,
                    onToggleClock: { toggleClock(snapshot: snapshot, now: timeline.date) }
                )

                ScrollView {
                    VStack(spacing: 6) {
                        fieldSection(snapshot: snapshot, names: names)
                        benchSection(snapshot: snapshot, names: names)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar(snapshot: snapshot, names: names, now: timeline.date)
            }
            .sheet(isPresented: $showScoreSheet, onDismiss: {
                store.finish(game: game, at: pendingEndedAt ?? .now)
                onFinished(game)
            }) {
                ScoreSheet(game: game)
            }
        }
        .onAppear {
            selectedHalf = store.snapshot(for: game, now: .now).currentHalf
        }
        .navigationTitle(TeamConfig.name)
        .navigationBarTitleDisplayMode(.inline)
        .keepsScreenAwake(!game.isFinished)
    }

    /// A section's caption-caps title, in `color` (normally secondary,
    /// green while the bench header is the active selection).
    func sectionHeader(_ title: String, color: Color = .secondary) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Wraps a row in a plain-styled button that resolves the tap against
    /// `snapshot` when pressed.
    func rowButton(_ target: Selection, snapshot: GameSnapshot, @ViewBuilder content: () -> some View) -> some View {
        Button {
            select(target, in: snapshot, now: .now)
        } label: {
            content()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LiveGameView(game: GameRecord(attendance: []))
    }
    .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
