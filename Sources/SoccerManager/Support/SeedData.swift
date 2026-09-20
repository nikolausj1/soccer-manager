import Foundation
import SwiftData
import SoccerManagerCore

/// Debug fixtures for the launch-argument scaffolding in `LaunchArguments`.
/// Every name here is a placeholder; real children's names must never
/// appear in the repo or in a screenshot.
enum SeedData {
    static let placeholderNames = ["Ash", "Blake", "Casey", "Drew", "Emerson", "Finley", "Gray", "Harper"]

    /// Deletes every persisted record.
    static func resetAll(context: ModelContext) {
        try? context.delete(model: GameEventRecord.self)
        try? context.delete(model: GameRecord.self)
        try? context.delete(model: PlayerRecord.self)
        try? context.save()
    }

    /// Inserts the eight placeholder players if the roster is currently
    /// empty. Leaves an existing roster untouched.
    @discardableResult
    static func seedRosterIfNeeded(context: ModelContext) -> [PlayerRecord] {
        let existing = (try? context.fetch(FetchDescriptor<PlayerRecord>())) ?? []
        guard existing.isEmpty else { return existing }

        var players: [PlayerRecord] = []
        for (index, name) in placeholderNames.enumerated() {
            let player = PlayerRecord(name: name, sortOrder: index)
            context.insert(player)
            players.append(player)
        }
        try? context.save()
        return players
    }

    /// Inserts two finished games, one from a week ago and one from two
    /// weeks ago, each with two halves, a few swaps, two keepers, and a
    /// plausible final score, so the games list, Summary, and Season all
    /// have content. Requires the full eight-player seeded roster; a no-op
    /// otherwise.
    static func seedFinishedGames(context: ModelContext) {
        let ids = activePlayerIDs(context: context)
        guard ids.count >= 8 else { return }

        makeFinishedGame(ids: ids, daysAgo: 14, context: context, ourScore: 3, theirScore: 2)
        makeFinishedGame(ids: ids, daysAgo: 7, context: context, ourScore: 1, theirScore: 1)
        try? context.save()
    }

    /// Inserts an unfinished game with all attending players and a
    /// five-player lineup whose current stints are all different: the
    /// keeper and two outfield players have been on since seven minutes
    /// ago, one outfield player since four minutes ago, and one since one
    /// minute ago (swapped in for a bench player who came off at the same
    /// moment). Against the default five-minute shift length that puts the
    /// readiness bars at red, amber, and green all at once.
    ///
    /// - Parameter stopped: When true, the clock is stopped thirty seconds
    ///   ago (half 1) instead of left running, so the game is at halftime.
    static func autostartLiveGame(context: ModelContext, stopped: Bool) {
        let ids = activePlayerIDs(context: context)
        guard ids.count >= 6 else { return }

        let sevenMinutesAgo = Date.now.addingTimeInterval(-7 * 60)
        let game = GameRecord(createdAt: sevenMinutesAgo, attendance: ids)
        context.insert(game)

        // Kickoff: two outfield players, the keeper, and a fifth player
        // (ids[5]) who will be substituted out later.
        var events: [GameEvent] = [
            .lineup(at: sevenMinutesAgo, half: 1, onField: [ids[0], ids[1], ids[4], ids[5]], keeper: ids[4]),
            .clockStart(at: sevenMinutesAgo, half: 1)
        ]

        // A third outfield player (ids[2]) joins four minutes ago with
        // nobody coming off, filling the fifth outfield slot with a
        // fresher stint.
        let fourMinutesAgo = Date.now.addingTimeInterval(-4 * 60)
        let beforeEntry = GameEngine.snapshot(events: events, attendance: ids, now: fourMinutesAgo)
        events.append(GameEngine.enter(snapshot: beforeEntry, player: ids[2], asKeeper: false, at: fourMinutesAgo))

        // One minute ago, ids[3] swaps on for ids[5]: the freshest outfield
        // stint, and a bench player whose rested time reads exactly 1:00.
        let oneMinuteAgo = Date.now.addingTimeInterval(-60)
        let beforeSwap = GameEngine.snapshot(events: events, attendance: ids, now: oneMinuteAgo)
        events.append(GameEngine.swap(snapshot: beforeSwap, off: ids[5], on: ids[3], at: oneMinuteAgo))

        if stopped {
            events.append(.clockStop(at: Date.now.addingTimeInterval(-30), half: 1))
        }

        insert(events, into: game, context: context)
        try? context.save()
    }

    /// Inserts an unfinished game with everyone attending and on the bench,
    /// and no events: the `setup` state, before any lineup or clock event.
    static func autostartLiveGameSetup(context: ModelContext) {
        let ids = activePlayerIDs(context: context)
        guard !ids.isEmpty else { return }
        let game = GameRecord(attendance: ids)
        context.insert(game)
        try? context.save()
    }

    /// Inserts an unfinished game whose clock started twenty-one minutes
    /// ago and has never stopped, so against the default twenty-minute
    /// half length the header shows a minute of red overtime.
    static func autostartLiveGameOvertime(context: ModelContext) {
        let ids = activePlayerIDs(context: context)
        guard !ids.isEmpty else { return }

        let twentyOneMinutesAgo = Date.now.addingTimeInterval(-21 * 60)
        let game = GameRecord(createdAt: twentyOneMinutesAgo, attendance: ids)
        context.insert(game)

        let initialOnField = Array(ids.prefix(5))
        let keeper = initialOnField.count >= 5 ? initialOnField[4] : nil
        let events: [GameEvent] = [
            .lineup(at: twentyOneMinutesAgo, half: 1, onField: initialOnField, keeper: keeper),
            .clockStart(at: twentyOneMinutesAgo, half: 1)
        ]

        insert(events, into: game, context: context)
        try? context.save()
    }

    // MARK: - Helpers

    private static func activePlayerIDs(context: ModelContext) -> [UUID] {
        let descriptor = FetchDescriptor<PlayerRecord>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let players = (try? context.fetch(descriptor)) ?? []
        return players.map(\.id)
    }

    private static func insert(_ events: [GameEvent], into game: GameRecord, context: ModelContext) {
        for event in events {
            let record = GameEventRecord(event: event)
            record.game = game
            context.insert(record)
        }
    }

    /// Builds one plausible finished game: a pre-game lineup with a keeper,
    /// two swaps in the first half, a keeper change early in the second
    /// half, a late swap, two full twenty-minute halves, and a final score.
    private static func makeFinishedGame(
        ids: [UUID],
        daysAgo: Int,
        context: ModelContext,
        ourScore: Int,
        theirScore: Int
    ) {
        let base = Date.now.addingTimeInterval(-Double(daysAgo) * 86400 - 3 * 3600)
        let game = GameRecord(createdAt: base, attendance: ids)
        context.insert(game)

        var events: [GameEvent] = []
        func snapshot(at offset: TimeInterval) -> GameSnapshot {
            GameEngine.snapshot(events: events, attendance: ids, now: base.addingTimeInterval(offset))
        }

        events.append(.lineup(at: base, half: 1, onField: Array(ids[0..<5]), keeper: ids[4]))
        events.append(.clockStart(at: base, half: 1))

        events.append(GameEngine.swap(snapshot: snapshot(at: 360), off: ids[0], on: ids[5], at: base.addingTimeInterval(360)))
        events.append(GameEngine.swap(snapshot: snapshot(at: 720), off: ids[1], on: ids[6], at: base.addingTimeInterval(720)))

        events.append(.clockStop(at: base.addingTimeInterval(1200), half: 1))
        events.append(.clockStart(at: base.addingTimeInterval(1260), half: 2))

        // A second keeper takes over early in the second half.
        events.append(GameEngine.swap(snapshot: snapshot(at: 1440), off: ids[4], on: ids[7], at: base.addingTimeInterval(1440)))
        events.append(GameEngine.swap(snapshot: snapshot(at: 2160), off: ids[2], on: ids[0], at: base.addingTimeInterval(2160)))

        let endedAt = base.addingTimeInterval(2460)
        events.append(.clockStop(at: endedAt, half: 2))

        insert(events, into: game, context: context)
        game.isFinished = true
        game.endedAt = endedAt
        game.ourScore = ourScore
        game.theirScore = theirScore
    }
}
