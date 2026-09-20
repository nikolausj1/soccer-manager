import SwiftUI

extension Color {
    /// Algeria flag green: accent color, the NEXT ON highlight, and the GK
    /// badge.
    static let algeriaGreen = Color(red: 0, green: 0.384, blue: 0.2)

    /// Algeria flag red: the NEXT OFF highlight.
    static let algeriaRed = Color(red: 0.824, green: 0.063, blue: 0.204)
}

/// Formats a duration as `m:ss`, for example `12:34` or `0:07`.
func formatClock(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded()))
    let minutes = total / 60
    let secs = total % 60
    return String(format: "%d:%02d", minutes, secs)
}

/// Formats a duration as whole minutes, for example `18m`.
func formatMinutes(_ seconds: TimeInterval) -> String {
    let minutes = Int((max(0, seconds) / 60).rounded())
    return "\(minutes)m"
}
