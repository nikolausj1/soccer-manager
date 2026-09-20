import SwiftUI

/// Shared `UserDefaults` keys and defaults for the app's user-adjustable
/// settings. Every reader (`RosterView`'s Steppers, `ClockHeader`'s
/// countdown, `LiveGameView`'s readiness bars) declares its own
/// `@AppStorage` property against these keys, so SwiftUI observes changes
/// and every reader stays in sync with no shared observable object needed.
enum AppSettings {
    /// The `UserDefaults` key for the half length, in minutes.
    static let halfLengthMinutesKey = "halfLengthMinutes"

    /// The `UserDefaults` key for the target shift length, in minutes.
    static let shiftLengthMinutesKey = "shiftLengthMinutes"

    /// The half length, in minutes, before Justin changes it in Settings.
    static let defaultHalfLengthMinutes = 20

    /// The target shift length, in minutes, before Justin changes it in
    /// Settings.
    static let defaultShiftLengthMinutes = 5
}
