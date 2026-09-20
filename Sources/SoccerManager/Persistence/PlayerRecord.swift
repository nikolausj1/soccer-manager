import Foundation
import SwiftData

/// A roster entry: one child's identity, kept separate from the engine,
/// which never sees names.
@Model
final class PlayerRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var isArchived: Bool
    var sortOrder: Int
    var createdAt: Date

    /// Creates a roster entry.
    ///
    /// - Parameters:
    ///   - id: A stable identity for this player. Defaults to a new `UUID`.
    ///   - name: The player's display name.
    ///   - isArchived: Whether the player is hidden from attendance while
    ///     staying in season history. Defaults to `false`.
    ///   - sortOrder: This player's position in the roster list.
    ///   - createdAt: When this player was added. Defaults to now.
    init(
        id: UUID = UUID(),
        name: String,
        isArchived: Bool = false,
        sortOrder: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.isArchived = isArchived
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
