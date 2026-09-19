import Foundation

/// One finished game's attendance and event history, as season totals need
/// it.
///
/// `SeasonTotals` treats every game it is given as finished; there is no
/// separate "in progress" state here, that distinction belongs to the app
/// layer.
public struct SeasonGame: Sendable {
    /// The players who attended this game.
    public let attendance: [UUID]

    /// This game's full event history.
    public let events: [GameEvent]

    /// The moment the game ended, used as the `now` when computing this
    /// game's final snapshot.
    public let endedAt: Date

    /// Creates a season game record.
    public init(attendance: [UUID], events: [GameEvent], endedAt: Date) {
        self.attendance = attendance
        self.events = events
        self.endedAt = endedAt
    }
}

/// One player's accumulated statistics across every game they attended this
/// season.
public struct SeasonStats: Equatable, Sendable {
    /// The number of games this player attended.
    public var gamesPlayed: Int

    /// Total field time across every attended game, including keeper time.
    public var fieldSeconds: TimeInterval

    /// Total keeper time across every attended game.
    public var keeperSeconds: TimeInterval

    /// Total number of keeper stints across every attended game.
    public var keeperStints: Int

    /// Creates season stats, defaulting to a player with no recorded games.
    public init(
        gamesPlayed: Int = 0,
        fieldSeconds: TimeInterval = 0,
        keeperSeconds: TimeInterval = 0,
        keeperStints: Int = 0
    ) {
        self.gamesPlayed = gamesPlayed
        self.fieldSeconds = fieldSeconds
        self.keeperSeconds = keeperSeconds
        self.keeperStints = keeperStints
    }
}

/// Computes season-long totals from a set of finished games.
public enum SeasonTotals {

    /// Sums every player's statistics across every given game.
    ///
    /// Each game contributes the per-player stats from
    /// `GameEngine.snapshot(events:attendance:now:)` evaluated at that
    /// game's `endedAt`. Every player in a game's attendance list gets
    /// `gamesPlayed` incremented by one for that game, even if they never
    /// appeared in a lineup.
    ///
    /// - Parameter games: The finished games to total, in any order.
    /// - Returns: A dictionary from player to their season statistics. A
    ///   player who attended no games has no entry.
    public static func compute(games: [SeasonGame]) -> [UUID: SeasonStats] {
        var totals: [UUID: SeasonStats] = [:]
        for game in games {
            let snapshot = GameEngine.snapshot(
                events: game.events,
                attendance: game.attendance,
                now: game.endedAt
            )
            for player in game.attendance {
                var playerTotals = totals[player] ?? SeasonStats()
                playerTotals.gamesPlayed += 1
                if let playerStats = snapshot.stats[player] {
                    playerTotals.fieldSeconds += playerStats.fieldSeconds
                    playerTotals.keeperSeconds += playerStats.keeperSeconds
                    playerTotals.keeperStints += playerStats.keeperStints
                }
                totals[player] = playerTotals
            }
        }
        return totals
    }
}
