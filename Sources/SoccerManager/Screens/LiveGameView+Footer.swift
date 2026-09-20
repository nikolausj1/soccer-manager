import SwiftUI
import SoccerManagerCore

/// The Live screen's bottom bar: Undo (when there is something to undo)
/// and the End Game button, which is available in every game state
/// (setup, running, stopped) so a test game can be discarded without first
/// stopping the clock.
extension LiveGameView {
    func bottomBar(snapshot: GameSnapshot, names: [UUID: String], now: Date) -> some View {
        HStack(spacing: 8) {
            if snapshot.canUndo {
                undoButton(snapshot: snapshot, names: names, now: now)
                endGameButton
            } else {
                Spacer()
                endGameButton
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .overlay(Divider(), alignment: .top)
    }

    /// Flexible: fills whatever space `endGameButton` (compact, on the
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

    /// Opens the End Game alert: "End and save" offers the final-score
    /// sheet and only actually finishes the game once that sheet is
    /// dismissed (see `LiveGameView.body`); "Discard game" deletes it
    /// outright, immediately, with nothing saved. An `.alert`, not a
    /// `.confirmationDialog`, so its buttons stay legible: a
    /// confirmationDialog renders as a floating card whose bottom row can
    /// land behind the floating tab bar, while an alert is a centered
    /// modal nothing else can cover.
    private var endGameButton: some View {
        Button("End Game") { showEndGameConfirm = true }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.algeriaRed)
            .alert(
                "End this game?",
                isPresented: $showEndGameConfirm
            ) {
                Button("End and save") {
                    pendingEndedAt = .now
                    showScoreSheet = true
                }
                Button("Discard game", role: .destructive) {
                    store.discard(game: game)
                }
                Button("Cancel", role: .cancel) {}
            }
    }
}
