import Foundation

/// Accumulated playing-time statistics for one attending player, as of a
/// particular moment in a game.
public struct PlayerStats: Equatable, Sendable {
    /// Total time on the field while the clock was running, including any
    /// time spent as keeper.
    public var fieldSeconds: TimeInterval

    /// Total time as keeper while the clock was running. A subset of
    /// `fieldSeconds`.
    public var keeperSeconds: TimeInterval

    /// The number of times this player became keeper.
    public var keeperStints: Int

    /// Running-clock time accumulated since this player most recently
    /// entered the field. Nil when the player is not currently on the
    /// field.
    public var currentStintSeconds: TimeInterval?

    /// Running-clock time accumulated since this player most recently
    /// became keeper. Nil when the player is not currently keeper.
    public var currentKeeperStintSeconds: TimeInterval?

    /// Running-clock time spent on the bench.
    public var benchSeconds: TimeInterval

    /// Running-clock time accumulated since this player most recently left
    /// the field, or since the start of the game for a player who begins
    /// on the bench. Every attending player starts a game with `0` here,
    /// not nil, because nobody is on the field until the first lineup
    /// event. Nil while the player is currently on the field.
    public var currentBenchStintSeconds: TimeInterval?

    /// Creates player stats, defaulting to a player who has not yet
    /// appeared in any lineup and so starts the game on the bench.
    public init(
        fieldSeconds: TimeInterval = 0,
        keeperSeconds: TimeInterval = 0,
        keeperStints: Int = 0,
        currentStintSeconds: TimeInterval? = nil,
        currentKeeperStintSeconds: TimeInterval? = nil,
        benchSeconds: TimeInterval = 0,
        currentBenchStintSeconds: TimeInterval? = 0
    ) {
        self.fieldSeconds = fieldSeconds
        self.keeperSeconds = keeperSeconds
        self.keeperStints = keeperStints
        self.currentStintSeconds = currentStintSeconds
        self.currentKeeperStintSeconds = currentKeeperStintSeconds
        self.benchSeconds = benchSeconds
        self.currentBenchStintSeconds = currentBenchStintSeconds
    }
}

/// A computed view of a game's state and per-player statistics at a single
/// moment, derived from a game's event history.
public struct GameSnapshot: Equatable, Sendable {
    /// Whether the clock is currently running.
    public var clockRunning: Bool

    /// The half of the most recent clock event, or 1 if the clock has never
    /// started.
    public var currentHalf: Int

    /// Running time accumulated in `currentHalf`.
    public var elapsedInHalf: TimeInterval

    /// Running time accumulated across the whole game.
    public var elapsedTotal: TimeInterval

    /// Players currently on the field, in the order given by the most
    /// recent lineup event.
    public var onField: [UUID]

    /// The current keeper, or nil if no one is in goal.
    public var keeper: UUID?

    /// Players currently on the bench, in attendance order.
    public var bench: [UUID]

    /// On-field players excluding the keeper, ranked longest-on first:
    /// `currentStintSeconds` descending, then `fieldSeconds` descending,
    /// then attendance order. A short current stint means a player only
    /// just came on, even if their game total is high, so it leads the
    /// ranking instead of only breaking ties in it.
    public var rankedOutfield: [UUID]

    /// Bench players ranked least-played first: `fieldSeconds` ascending,
    /// then `currentBenchStintSeconds` descending (longest rested first),
    /// then attendance order.
    public var rankedBench: [UUID]

    /// The outfield player due to come off next, that is `rankedOutfield`'s
    /// first element. Nil when no one is on the field as an outfield
    /// player.
    public var nextOff: UUID?

    /// The bench player due to go on next, that is `rankedBench`'s first
    /// element. Nil when the bench is empty.
    public var nextOn: UUID?

    /// Per-player statistics, one entry for every attending player.
    public var stats: [UUID: PlayerStats]

    /// Whether at least one lineup event exists to undo.
    public var canUndo: Bool

    /// Creates a game snapshot.
    public init(
        clockRunning: Bool,
        currentHalf: Int,
        elapsedInHalf: TimeInterval,
        elapsedTotal: TimeInterval,
        onField: [UUID] = [],
        keeper: UUID? = nil,
        bench: [UUID] = [],
        rankedOutfield: [UUID] = [],
        rankedBench: [UUID] = [],
        nextOff: UUID? = nil,
        nextOn: UUID? = nil,
        stats: [UUID: PlayerStats] = [:],
        canUndo: Bool = false
    ) {
        self.clockRunning = clockRunning
        self.currentHalf = currentHalf
        self.elapsedInHalf = elapsedInHalf
        self.elapsedTotal = elapsedTotal
        self.onField = onField
        self.keeper = keeper
        self.bench = bench
        self.rankedOutfield = rankedOutfield
        self.rankedBench = rankedBench
        self.nextOff = nextOff
        self.nextOn = nextOn
        self.stats = stats
        self.canUndo = canUndo
    }
}
