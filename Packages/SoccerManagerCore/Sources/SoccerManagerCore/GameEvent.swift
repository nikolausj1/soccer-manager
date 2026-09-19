import Foundation

/// A single timestamped occurrence in a game's history.
///
/// A game is stored as an ordered list of `GameEvent` values. `clockStart` and
/// `clockStop` mark when the running clock starts and stops for a half.
/// `lineup` events are full snapshots: every `lineup` event carries the
/// complete set of players on the field and who is keeper immediately after
/// the change, not a delta from the previous lineup. That makes undo simple,
/// since deleting the most recent `lineup` event always leaves a valid
/// previous snapshot in place.
public struct GameEvent: Codable, Equatable, Identifiable, Sendable {
    /// The kind of occurrence this event represents.
    public enum Kind: String, Codable, Sendable {
        case clockStart
        case clockStop
        case lineup
    }

    /// A stable identity for this event, distinct from its content.
    public let id: UUID

    /// The wall-clock time the event occurred.
    public let at: Date

    /// Which kind of event this is.
    public let kind: Kind

    /// The half this event belongs to. On `clockStart` and `clockStop` events
    /// this is the half being started or stopped, 1 or 2. On `lineup` events
    /// this is the half in effect at the time the lineup changed.
    public let half: Int

    /// The full set of players on the field after this event. Populated only
    /// on `lineup` events; empty otherwise.
    public let onField: [UUID]

    /// The keeper after this event, or nil if no one is in goal. Populated
    /// only on `lineup` events; nil otherwise. When non-nil this player must
    /// also be present in `onField`.
    public let keeper: UUID?

    /// Creates a game event.
    ///
    /// - Parameters:
    ///   - id: A stable identity for the event. Defaults to a new `UUID`.
    ///   - at: The wall-clock time the event occurred.
    ///   - kind: Which kind of event this is.
    ///   - half: The half this event belongs to.
    ///   - onField: The full set of players on the field after this event.
    ///     Only meaningful for `lineup` events.
    ///   - keeper: The keeper after this event. Only meaningful for `lineup`
    ///     events.
    public init(
        id: UUID = UUID(),
        at: Date,
        kind: Kind,
        half: Int,
        onField: [UUID] = [],
        keeper: UUID? = nil
    ) {
        self.id = id
        self.at = at
        self.kind = kind
        self.half = half
        self.onField = onField
        self.keeper = keeper
    }

    /// Creates a `clockStart` event for the given half.
    public static func clockStart(at: Date, half: Int) -> GameEvent {
        GameEvent(at: at, kind: .clockStart, half: half)
    }

    /// Creates a `clockStop` event for the given half.
    public static func clockStop(at: Date, half: Int) -> GameEvent {
        GameEvent(at: at, kind: .clockStop, half: half)
    }

    /// Creates a `lineup` event carrying a full snapshot of the field and
    /// keeper after the change.
    public static func lineup(at: Date, half: Int, onField: [UUID], keeper: UUID?) -> GameEvent {
        GameEvent(at: at, kind: .lineup, half: half, onField: onField, keeper: keeper)
    }
}
