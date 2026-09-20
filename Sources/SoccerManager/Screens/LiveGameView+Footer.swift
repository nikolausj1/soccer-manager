import SwiftUI
import SoccerManagerCore

/// The Live screen's bottom bar: Undo on the left (when there is something
/// to undo) and, on the right, whichever single action the current phase
/// calls for. The bar disappears entirely when neither has anything to
/// show, which only happens at kickoff before any lineup has been set.
extension LiveGameView {
    @ViewBuilder
    func bottomBar(snapshot: GameSnapshot, names: [UUID: String], now: Date, phase: GamePhase) -> some View {
        if snapshot.canUndo || phase.showsFooterButton {
            HStack(spacing: 8) {
                if snapshot.canUndo {
                    undoButton(snapshot: snapshot, names: names, now: now)
                } else {
                    Spacer()
                }
                phaseButton(phase: phase, snapshot: snapshot)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .overlay(Divider(), alignment: .top)
        }
    }

    /// Flexible: fills whatever space the phase button (compact, on the
    /// right) leaves, truncating its own label rather than pushing the row
    /// taller.
    func undoButton(snapshot: GameSnapshot, names: [UUID: String], now: Date) -> some View {
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

    /// The footer's lower-right button for `phase`: nothing at kickoff or
    /// full time (transient), "End Half" during the first half, "End
    /// Game" at halftime and during the second half.
    @ViewBuilder
    private func phaseButton(phase: GamePhase, snapshot: GameSnapshot) -> some View {
        switch phase {
        case .kickoff, .fullTime:
            EmptyView()
        case .firstHalf:
            endHalfButton
        case .halftime, .secondHalf:
            endGameButton(snapshot: snapshot)
        }
    }

    /// Opens the "End the first half?" alert. Confirming appends the
    /// `clockStop` for half 1; the header then shows halftime on its own,
    /// since phase is derived, not stored.
    private var endHalfButton: some View {
        Button("End Half") { showEndHalfConfirm = true }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.algeriaRed)
            .alert("End the first half?", isPresented: $showEndHalfConfirm) {
                Button("End Half", role: .destructive) {
                    store.append(.clockStop(at: .now, half: 1), to: game)
                }
                Button("Cancel", role: .cancel) {}
            }
    }

    /// Opens the "End the game?" alert. Confirming stops the clock first
    /// if it is still running (halftime already has it stopped), then
    /// hands off to the same `pendingEndedAt` and score sheet flow "End
    /// and save" used before.
    private func endGameButton(snapshot: GameSnapshot) -> some View {
        Button("End Game") { showEndGameConfirm = true }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.algeriaRed)
            .alert("End the game?", isPresented: $showEndGameConfirm) {
                Button("End Game", role: .destructive) {
                    let now = Date.now
                    if snapshot.clockRunning {
                        store.append(.clockStop(at: now, half: snapshot.currentHalf), to: game)
                    }
                    pendingEndedAt = now
                    showScoreSheet = true
                }
                Button("Cancel", role: .cancel) {}
            }
    }
}

private extension GamePhase {
    /// Whether the footer's right-hand slot has a button to show for this
    /// phase (kickoff and full time show nothing there).
    var showsFooterButton: Bool {
        switch self {
        case .firstHalf, .halftime, .secondHalf: return true
        case .kickoff, .fullTime: return false
        }
    }
}
