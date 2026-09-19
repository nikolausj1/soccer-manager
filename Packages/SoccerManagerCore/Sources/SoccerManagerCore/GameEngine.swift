import Foundation

/// Pure functions that turn a game's event log into a point-in-time snapshot,
/// and that build the lineup events the app uses to record substitutions.
///
/// `GameEngine` holds no state of its own. Every function takes the event
/// history it needs and returns a new value; nothing is mutated in place.
public enum GameEngine {

    /// Computes the game's state and every attending player's statistics at
    /// `now`, from its full event history.
    ///
    /// Events are processed in timestamp order (a stable sort, so events
    /// that share a timestamp keep their relative input order). Time accrues
    /// to on-field players, the keeper, and bench players for each interval
    /// during which the clock is running, ending at the next event or at
    /// `now` if the clock is still running. Lineup changes while the clock
    /// is stopped move players between field and bench without accruing any
    /// seconds. Lineup entries for players not present in `attendance` are
    /// ignored, as is a keeper who is not also listed on the field.
    ///
    /// - Parameters:
    ///   - events: The game's full event history, in any order.
    ///   - attendance: The players who attended, in attendance order. This
    ///     order is used for bench listing and as the final ranking
    ///     tiebreak.
    ///   - now: The moment to compute the snapshot as of. Only matters when
    ///     the clock is currently running, since that leaves one interval
    ///     open with no closing `clockStop` event yet.
    /// - Returns: The computed snapshot.
    public static func snapshot(events: [GameEvent], attendance: [UUID], now: Date) -> GameSnapshot {
        let sorted = events.sorted { $0.at < $1.at }
        let attendanceSet = Set(attendance)

        // The half of the most recent clock event, 1 if none. This is a
        // property of the event log alone, independent of whether any given
        // clock event actually changed the running state.
        var currentHalf = 1
        for event in sorted where event.kind == .clockStart || event.kind == .clockStop {
            currentHalf = event.half
        }

        var stats: [UUID: PlayerStats] = [:]
        for player in attendance {
            stats[player] = PlayerStats()
        }

        var onField: [UUID] = []
        var keeper: UUID?
        var clockRunning = false
        var openIntervalStart: Date?
        var openIntervalHalf = currentHalf
        var elapsedTotal: TimeInterval = 0
        var elapsedInHalf: TimeInterval = 0

        // Accrues the currently open running interval up to `until`, then
        // moves the interval's start forward to `until`. A no-op when the
        // clock is not running.
        func accrue(until: Date) {
            guard clockRunning, let start = openIntervalStart else { return }
            let duration = max(0, until.timeIntervalSince(start))
            elapsedTotal += duration
            // elapsedInHalf only credits intervals opened by a clockStart
            // whose half matches the half we ultimately end up in, so it
            // reflects only the current half even though elapsedTotal keeps
            // every half's time.
            if openIntervalHalf == currentHalf {
                elapsedInHalf += duration
            }
            let onFieldSet = Set(onField)
            // Each update reads the player's stats into a local copy,
            // mutates the copy, then writes it back, rather than mutating
            // through the dictionary subscript in one expression. Swift
            // treats a read and write of the same subscript in a single
            // statement as overlapping access, which the compiler rejects.
            for player in onField {
                if var playerStats = stats[player] {
                    playerStats.fieldSeconds += duration
                    playerStats.currentStintSeconds = (playerStats.currentStintSeconds ?? 0) + duration
                    stats[player] = playerStats
                }
            }
            if let keeper {
                if var keeperStats = stats[keeper] {
                    keeperStats.keeperSeconds += duration
                    keeperStats.currentKeeperStintSeconds = (keeperStats.currentKeeperStintSeconds ?? 0) + duration
                    stats[keeper] = keeperStats
                }
            }
            for player in attendance where !onFieldSet.contains(player) {
                if var playerStats = stats[player] {
                    playerStats.benchSeconds += duration
                    stats[player] = playerStats
                }
            }
            openIntervalStart = until
        }

        for event in sorted {
            switch event.kind {
            case .clockStart:
                accrue(until: event.at)
                if !clockRunning {
                    clockRunning = true
                    openIntervalStart = event.at
                    openIntervalHalf = event.half
                }
                // A start while already running is ignored.

            case .clockStop:
                accrue(until: event.at)
                if clockRunning {
                    clockRunning = false
                    openIntervalStart = nil
                }
                // A stop while already stopped is ignored.

            case .lineup:
                accrue(until: event.at)

                let newOnField = event.onField.filter { attendanceSet.contains($0) }
                let candidateKeeper = event.keeper.flatMap { attendanceSet.contains($0) ? $0 : nil }
                // A keeper must also be on the field; a malformed event
                // cannot make a player keeper without also fielding them.
                let newKeeper = candidateKeeper.flatMap { newOnField.contains($0) ? $0 : nil }

                let previousOnFieldSet = Set(onField)
                let newOnFieldSet = Set(newOnField)

                // A player newly on the field starts a fresh current stint.
                for player in newOnField where !previousOnFieldSet.contains(player) {
                    stats[player]?.currentStintSeconds = 0
                }
                // A player leaving the field has no current stint.
                for player in onField where !newOnFieldSet.contains(player) {
                    stats[player]?.currentStintSeconds = nil
                }

                if newKeeper != keeper {
                    if let oldKeeper = keeper {
                        stats[oldKeeper]?.currentKeeperStintSeconds = nil
                    }
                    if let newKeeper {
                        stats[newKeeper]?.currentKeeperStintSeconds = 0
                        stats[newKeeper]?.keeperStints += 1
                    }
                }

                onField = newOnField
                keeper = newKeeper
            }
        }

        // Close out whatever interval is still open as of `now`.
        accrue(until: now)

        let onFieldSet = Set(onField)
        let bench = attendance.filter { !onFieldSet.contains($0) }
        let outfield = onField.filter { $0 != keeper }

        // Attendance order is the final tiebreak for both rankings. Built
        // without Dictionary(uniqueKeysWithValues:) so a caller that ever
        // passes a duplicated UUID degrades gracefully instead of trapping.
        var attendanceIndex: [UUID: Int] = [:]
        for (index, player) in attendance.enumerated() where attendanceIndex[player] == nil {
            attendanceIndex[player] = index
        }

        let rankedOutfield = outfield.sorted { a, b in
            let statsA = stats[a] ?? PlayerStats()
            let statsB = stats[b] ?? PlayerStats()
            if statsA.fieldSeconds != statsB.fieldSeconds {
                return statsA.fieldSeconds > statsB.fieldSeconds
            }
            let stintA = statsA.currentStintSeconds ?? 0
            let stintB = statsB.currentStintSeconds ?? 0
            if stintA != stintB {
                return stintA > stintB
            }
            return (attendanceIndex[a] ?? Int.max) < (attendanceIndex[b] ?? Int.max)
        }

        let rankedBench = bench.sorted { a, b in
            let statsA = stats[a] ?? PlayerStats()
            let statsB = stats[b] ?? PlayerStats()
            if statsA.fieldSeconds != statsB.fieldSeconds {
                return statsA.fieldSeconds < statsB.fieldSeconds
            }
            if statsA.benchSeconds != statsB.benchSeconds {
                return statsA.benchSeconds > statsB.benchSeconds
            }
            return (attendanceIndex[a] ?? Int.max) < (attendanceIndex[b] ?? Int.max)
        }

        let canUndo = sorted.contains { $0.kind == .lineup }

        return GameSnapshot(
            clockRunning: clockRunning,
            currentHalf: currentHalf,
            elapsedInHalf: elapsedInHalf,
            elapsedTotal: elapsedTotal,
            onField: onField,
            keeper: keeper,
            bench: bench,
            rankedOutfield: rankedOutfield,
            rankedBench: rankedBench,
            nextOff: rankedOutfield.first,
            nextOn: rankedBench.first,
            stats: stats,
            canUndo: canUndo
        )
    }

    /// Returns `events` with its most recent lineup event removed.
    ///
    /// "Most recent" is determined by sorting the lineup events by `at`; if
    /// several share the latest timestamp, the one that appears last in
    /// `events` wins, consistent with the stable sort `snapshot` uses
    /// elsewhere. Every other event keeps its original position. This is
    /// always a valid undo, because the snapshot after removal falls back to
    /// the lineup event before it, or to the empty starting lineup if there
    /// is none.
    ///
    /// - Parameter events: The game's full event history, in any order.
    /// - Returns: `events` unchanged if it contains no lineup event,
    ///   otherwise `events` with the most recent lineup event removed.
    public static func removingLastLineup(_ events: [GameEvent]) -> [GameEvent] {
        let lineupsByTime = events
            .filter { $0.kind == .lineup }
            .sorted { $0.at < $1.at }
        guard let mostRecent = lineupsByTime.last else {
            return events
        }
        var result = events
        if let index = result.firstIndex(where: { $0.id == mostRecent.id }) {
            result.remove(at: index)
        }
        return result
    }

    /// Builds the lineup event for swapping one player off the field for
    /// another. If `off` was the keeper, `on` becomes the new keeper.
    ///
    /// - Parameters:
    ///   - snapshot: The game's current snapshot.
    ///   - off: The on-field player coming off.
    ///   - on: The bench player going on, in `off`'s place.
    ///   - at: When the swap happens.
    /// - Returns: A new lineup event carrying the resulting full snapshot.
    public static func swap(snapshot: GameSnapshot, off: UUID, on: UUID, at: Date) -> GameEvent {
        var newOnField = snapshot.onField
        if let index = newOnField.firstIndex(of: off) {
            newOnField[index] = on
        } else if !newOnField.contains(on) {
            newOnField.append(on)
        }
        let newKeeper = (snapshot.keeper == off) ? on : snapshot.keeper
        return GameEvent.lineup(at: at, half: snapshot.currentHalf, onField: newOnField, keeper: newKeeper)
    }

    /// Builds the lineup event for moving the keeper role to another player
    /// who is already on the field. The player who was keeper stays on the
    /// field as an outfield player.
    ///
    /// - Parameters:
    ///   - snapshot: The game's current snapshot.
    ///   - newKeeper: The on-field player who becomes keeper.
    ///   - at: When the change happens.
    /// - Returns: A new lineup event carrying the resulting full snapshot.
    public static func tradeKeeper(snapshot: GameSnapshot, newKeeper: UUID, at: Date) -> GameEvent {
        GameEvent.lineup(at: at, half: snapshot.currentHalf, onField: snapshot.onField, keeper: newKeeper)
    }

    /// Builds the lineup event for a bench player joining the field with no
    /// one coming off. Used to field more than the usual number of players,
    /// or to fill a short-handed lineup.
    ///
    /// - Parameters:
    ///   - snapshot: The game's current snapshot.
    ///   - player: The bench player entering the field.
    ///   - asKeeper: Whether the entering player becomes keeper. When true,
    ///     any existing keeper stays on the field as an outfield player.
    ///   - at: When the entry happens.
    /// - Returns: A new lineup event carrying the resulting full snapshot.
    public static func enter(snapshot: GameSnapshot, player: UUID, asKeeper: Bool, at: Date) -> GameEvent {
        var newOnField = snapshot.onField
        if !newOnField.contains(player) {
            newOnField.append(player)
        }
        let newKeeper = asKeeper ? player : snapshot.keeper
        return GameEvent.lineup(at: at, half: snapshot.currentHalf, onField: newOnField, keeper: newKeeper)
    }

    /// Builds the lineup event for an on-field player going to the bench
    /// with no replacement. If the player was keeper, the game has no
    /// keeper afterward.
    ///
    /// - Parameters:
    ///   - snapshot: The game's current snapshot.
    ///   - player: The on-field player leaving.
    ///   - at: When the departure happens.
    /// - Returns: A new lineup event carrying the resulting full snapshot.
    public static func leave(snapshot: GameSnapshot, player: UUID, at: Date) -> GameEvent {
        let newOnField = snapshot.onField.filter { $0 != player }
        let newKeeper = (snapshot.keeper == player) ? nil : snapshot.keeper
        return GameEvent.lineup(at: at, half: snapshot.currentHalf, onField: newOnField, keeper: newKeeper)
    }

    /// Builds a lineup event that replaces the whole field and keeper in one
    /// step, for example the pre-game lineup or a full reset.
    ///
    /// - Parameters:
    ///   - snapshot: The game's current snapshot.
    ///   - onField: The complete new set of on-field players.
    ///   - keeper: The new keeper, or nil for none.
    ///   - at: When the change happens.
    /// - Returns: A new lineup event carrying the given snapshot.
    public static func setLineup(snapshot: GameSnapshot, onField: [UUID], keeper: UUID?, at: Date) -> GameEvent {
        GameEvent.lineup(at: at, half: snapshot.currentHalf, onField: onField, keeper: keeper)
    }
}
