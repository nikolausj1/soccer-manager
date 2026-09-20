import Foundation

/// Fixed identity and constants for the one team this app tracks.
enum TeamConfig {
    /// The team's display name, shown as the Game tab's navigation title.
    static let name = "Algeria"

    /// The number of field slots (outfield plus keeper) the Live screen
    /// shows, including empty placeholders when fewer players are on.
    static let fieldSize = 5

    /// The standard length of one half, in seconds. Display only; nothing
    /// in the app auto-stops the clock at this mark.
    static let halfLengthSeconds: TimeInterval = 1200
}
