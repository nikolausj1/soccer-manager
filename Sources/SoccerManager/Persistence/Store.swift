import Foundation
import SwiftData
import SoccerManagerCore

/// Persistence operations for a game's event log, layered on the engine's
/// pure functions. Every mutating call saves the model context immediately,
/// so a force-quit never loses more than a write already in flight.
struct GameStore {
    let context: ModelContext

    /// Appends a new event to `game`'s history and saves immediately.
    func append(_ event: GameEvent, to game: GameRecord) {
        let record = GameEventRecord(event: event)
        record.game = game
        context.insert(record)
        save()
    }

    /// Removes the most recent lineup event from `game`, using the engine
    /// to determine which record that is, and saves immediately. A no-op
    /// if there is no lineup event to remove.
    func undoLastLineup(in game: GameRecord) {
        let events = game.events.map(\.event)
        let reduced = GameEngine.removingLastLineup(events)
        guard reduced.count < events.count else { return }
        let keptIDs = Set(reduced.map(\.id))
        for record in game.events where !keptIDs.contains(record.id) {
            context.delete(record)
        }
        save()
    }

    /// Computes `game`'s current snapshot as of `now`.
    func snapshot(for game: GameRecord, now: Date) -> GameSnapshot {
        GameEngine.snapshot(events: game.events.map(\.event), attendance: game.attendance, now: now)
    }

    /// Marks `game` finished at `date` and saves immediately.
    func finish(game: GameRecord, at date: Date) {
        game.isFinished = true
        game.endedAt = date
        save()
    }

    /// Deletes `game` and its events entirely. The only way to back out of
    /// a game created by mistake, before its clock has ever started.
    func discard(game: GameRecord) {
        context.delete(game)
        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            assertionFailure("GameStore save failed: \(error)")
        }
    }
}
