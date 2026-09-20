import Foundation
import SwiftData
import SoccerManagerCore

/// One persisted `GameEvent`, append-only: a new lineup change adds a
/// record, and Undo removes the most recent one. Never edited in place.
@Model
final class GameEventRecord {
    @Attribute(.unique) var id: UUID
    var at: Date

    /// The raw value of the engine's `GameEvent.Kind`.
    var kind: String

    var half: Int
    var onField: [UUID]
    var keeper: UUID?
    var game: GameRecord?

    /// Creates a record from an engine event, preserving its identity.
    init(event: GameEvent) {
        self.id = event.id
        self.at = event.at
        self.kind = event.kind.rawValue
        self.half = event.half
        self.onField = event.onField
        self.keeper = event.keeper
    }

    /// This record as the engine's own `GameEvent` value. Falls back to
    /// `.lineup` for `kind` in the theoretical case of a corrupted raw
    /// value, since that never happens through this app's own writes.
    var event: GameEvent {
        GameEvent(
            id: id,
            at: at,
            kind: GameEvent.Kind(rawValue: kind) ?? .lineup,
            half: half,
            onField: onField,
            keeper: keeper
        )
    }
}
