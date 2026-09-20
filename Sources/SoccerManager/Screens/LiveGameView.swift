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
/// pinned above the scrolling field and bench lists, and Undo plus the
/// End Game / Discard footer sit in a bottom `safeAreaInset` above the tab
/// bar. Only the field and bench rows scroll.
struct LiveGameView: View {
    let game: GameRecord
    var onFinished: (GameRecord) -> Void = { _ in }

    @Environment(\.modelContext) var context
    @Query var allPlayers: [PlayerRecord]

    @State var selectedHalf = 1
    @State var selected: Selection?
    @State private var showEndGameConfirm = false
    @State private var showDiscardConfirm = false

    var store: GameStore { GameStore(context: context) }

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
                .overlay(Divider(), alignment: .bottom)

                ScrollView {
                    VStack(spacing: 4) {
                        fieldSection(snapshot: snapshot, names: names)
                        benchSection(snapshot: snapshot, names: names)
                    }
                    .padding(.vertical, 2)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar(snapshot: snapshot, names: names, now: timeline.date)
            }
        }
        .onAppear {
            selectedHalf = store.snapshot(for: game, now: .now).currentHalf
        }
        .navigationTitle(TeamConfig.name)
        .navigationBarTitleDisplayMode(.inline)
        .keepsScreenAwake(!game.isFinished)
    }

    // MARK: - Sections

    private func fieldSection(snapshot: GameSnapshot, names: [UUID: String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Field")

            if let keeper = snapshot.keeper {
                rowButton(.player(keeper), snapshot: snapshot) {
                    PlayerRow(
                        name: names[keeper] ?? "Unknown",
                        stats: snapshot.stats[keeper] ?? PlayerStats(),
                        isOnField: true,
                        isKeeper: true,
                        isSelected: selected == .player(keeper)
                    )
                }
            } else {
                rowButton(.keeperSlot, snapshot: snapshot) {
                    PlaceholderSlotRow(label: "No keeper", isSelected: selected == .keeperSlot)
                }
            }

            ForEach(Array(snapshot.rankedOutfield.enumerated()), id: \.element) { index, id in
                rowButton(.player(id), snapshot: snapshot) {
                    PlayerRow(
                        name: names[id] ?? "Unknown",
                        stats: snapshot.stats[id] ?? PlayerStats(),
                        isOnField: true,
                        statusBadge: index == 0 ? .nextOff : nil,
                        isSelected: selected == .player(id)
                    )
                }
            }

            // The field holds `fieldSize` total including the keeper, so an
            // empty keeper slot (the "No keeper" row above) already accounts
            // for one of those slots and must not also count as an empty
            // outfield slot.
            let emptySlots = max(
                0,
                TeamConfig.fieldSize - snapshot.onField.count - (snapshot.keeper == nil ? 1 : 0)
            )
            ForEach(0..<emptySlots, id: \.self) { _ in
                rowButton(.emptySlot, snapshot: snapshot) {
                    PlaceholderSlotRow(label: "Empty slot", isSelected: selected == .emptySlot)
                }
            }
        }
        .padding(.horizontal)
    }

    private func benchSection(snapshot: GameSnapshot, names: [UUID: String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                select(.benchHeader, in: snapshot, now: .now)
            } label: {
                HStack {
                    sectionHeader("Bench")
                        .foregroundStyle(selected == .benchHeader ? Color.accentColor : .secondary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(Array(snapshot.rankedBench.enumerated()), id: \.element) { index, id in
                rowButton(.player(id), snapshot: snapshot) {
                    PlayerRow(
                        name: names[id] ?? "Unknown",
                        stats: snapshot.stats[id] ?? PlayerStats(),
                        statusBadge: index == 0 ? .nextOn : nil,
                        isSelected: selected == .player(id)
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private func bottomBar(snapshot: GameSnapshot, names: [UUID: String], now: Date) -> some View {
        if snapshot.canUndo || !snapshot.clockRunning {
            HStack(spacing: 8) {
                if snapshot.canUndo {
                    undoButton(snapshot: snapshot, names: names, now: now)
                    footer(snapshot: snapshot)
                } else {
                    Spacer()
                    footer(snapshot: snapshot)
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .overlay(Divider(), alignment: .top)
        }
    }

    /// Flexible: fills whatever space `footer` (compact, on the right)
    /// leaves, truncating its own label rather than pushing the row taller.
    private func undoButton(snapshot: GameSnapshot, names: [UUID: String], now: Date) -> some View {
        Button {
            store.undoLastLineup(in: game)
            selected = nil
        } label: {
            Text(undoLabel(snapshot: snapshot, names: names, now: now))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private func footer(snapshot: GameSnapshot) -> some View {
        let hasClockStarted = game.events.contains { $0.kind == GameEvent.Kind.clockStart.rawValue }

        if snapshot.clockRunning {
            EmptyView()
        } else if hasClockStarted {
            Button("End Game") { showEndGameConfirm = true }
                .buttonStyle(.borderedProminent)
                .tint(.algeriaRed)
                .confirmationDialog(
                    "End this game?",
                    isPresented: $showEndGameConfirm,
                    titleVisibility: .visible
                ) {
                    Button("End Game", role: .destructive) {
                        store.finish(game: game, at: .now)
                        onFinished(game)
                    }
                    Button("Cancel", role: .cancel) {}
                }
        } else {
            Button("Discard Game", role: .destructive) { showDiscardConfirm = true }
                .buttonStyle(.bordered)
                .tint(.algeriaRed)
                .confirmationDialog(
                    "Discard this game?",
                    isPresented: $showDiscardConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Discard Game", role: .destructive) {
                        store.discard(game: game)
                    }
                    Button("Cancel", role: .cancel) {}
                }
        }
    }

    /// Wraps a row in a plain-styled button that resolves the tap against
    /// `snapshot` when pressed.
    private func rowButton(_ target: Selection, snapshot: GameSnapshot, @ViewBuilder content: () -> some View) -> some View {
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
