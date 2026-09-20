import Foundation
import SoccerManagerCore

/// Where a game currently stands in its clock lifecycle. Never stored:
/// always derived fresh from the event log and the snapshot computed from
/// it, the same way everything else about a game is.
enum GamePhase: Equatable {
    /// No clock event has ever been recorded. The pre-game lineup can
    /// still be set; the clock has not run at all.
    case kickoff
    /// The clock is running in the first half.
    case firstHalf
    /// The first half ended and the second has not started yet.
    case halftime
    /// The clock is running in the second half.
    case secondHalf
    /// The second half just ended. Transient: the same action that
    /// reaches this phase immediately starts the score sheet flow, so the
    /// Live screen essentially never renders it.
    case fullTime

    /// Short text for the games list's in-progress row.
    var displayText: String {
        switch self {
        case .kickoff: return "Kickoff"
        case .firstHalf: return "1st Half"
        case .halftime: return "Halftime"
        case .secondHalf: return "2nd Half"
        case .fullTime: return "Full Time"
        }
    }

    /// Derives the phase from a game's full event history and the
    /// snapshot computed from it.
    ///
    /// If the clock is running, the phase follows directly from
    /// `snapshot.currentHalf`. Otherwise, the most recent clock event (by
    /// timestamp) determines it: with no clock event at all, the game
    /// hasn't kicked off; otherwise that event must be a `clockStop`,
    /// because a `clockStart` always leaves the clock running, whether it
    /// began a run or was a redundant no-op during one, and there is
    /// nothing after it in the log to stop it again.
    static func current(events: [GameEvent], snapshot: GameSnapshot) -> GamePhase {
        if snapshot.clockRunning {
            return snapshot.currentHalf == 1 ? .firstHalf : .secondHalf
        }
        let lastClockEvent = events
            .filter { $0.kind == .clockStart || $0.kind == .clockStop }
            .max { $0.at < $1.at }
        guard let lastClockEvent else { return .kickoff }
        return lastClockEvent.half == 1 ? .halftime : .fullTime
    }
}
