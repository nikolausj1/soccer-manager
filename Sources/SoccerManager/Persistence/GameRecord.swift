import Foundation
import SwiftData

/// One game: its attendance, whether it is finished, and its full event
/// history. Mirrors the engine's model one to one so `GameEngine`'s pure
/// functions can be re-run against stored data at any time.
@Model
final class GameRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    /// The players who attended, in attendance order. The engine's ranking
    /// tiebreak and the bench listing both rely on this order.
    var attendance: [UUID]

    var isFinished: Bool
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \GameEventRecord.game)
    var events: [GameEventRecord] = []

    /// Creates a game record.
    ///
    /// - Parameters:
    ///   - id: A stable identity for this game. Defaults to a new `UUID`.
    ///   - createdAt: When this game was created. Defaults to now.
    ///   - attendance: The attending players, in attendance order.
    ///   - isFinished: Whether the game has been ended. Defaults to `false`.
    ///   - endedAt: When the game was ended, if it has been.
    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        attendance: [UUID],
        isFinished: Bool = false,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.attendance = attendance
        self.isFinished = isFinished
        self.endedAt = endedAt
    }
}
