import SwiftUI

/// How far a player's current stint (on the field) or rest (on the bench)
/// has run against the target shift length, shown as a thin bar under
/// their row. Nil only for the keeper row, which shows no bar.
struct Readiness {
    /// `currentStintSeconds / shiftLengthSeconds` for an outfield row, or
    /// `currentBenchStintSeconds / shiftLengthSeconds` for a bench row,
    /// left unclamped so `isDue` can tell "past" the shift length from
    /// merely "at" it.
    let ratio: Double

    /// Whether this bar can turn amber or red and show a DUE badge (an
    /// outfield row, where a long stint is something to act on) or always
    /// stays green (a bench row, where rest is never urgent).
    let showsUrgency: Bool

    /// Whether the stint has reached or passed the target shift length.
    /// Always false for a bench row.
    var isDue: Bool { showsUrgency && ratio >= 1 }

    /// The bar's fill amount, clamped to fit its track.
    var fillFraction: Double { min(1, max(0, ratio)) }

    /// Green under 0.6 of the shift length, amber from 0.6 up to the shift
    /// length, Algeria red at or past it, for an outfield row. Always
    /// green for a bench row.
    var color: Color {
        guard showsUrgency else { return .algeriaGreen }
        if ratio >= 1 { return .algeriaRed }
        if ratio >= 0.6 { return .orange }
        return .algeriaGreen
    }
}

/// The thin readiness progress bar shown under an outfield or bench row's
/// name, in `PlayerRow`.
struct ReadinessBar: View {
    let readiness: Readiness

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.08))
                Capsule().fill(readiness.color)
                    .frame(width: proxy.size.width * readiness.fillFraction)
            }
        }
        .frame(height: 5)
        .frame(maxWidth: 160)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ReadinessBar(readiness: Readiness(ratio: 0.3, showsUrgency: true))
        ReadinessBar(readiness: Readiness(ratio: 0.8, showsUrgency: true))
        ReadinessBar(readiness: Readiness(ratio: 1.2, showsUrgency: true))
        ReadinessBar(readiness: Readiness(ratio: 1.4, showsUrgency: false))
    }
    .padding()
}
