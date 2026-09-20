import SwiftUI
import SoccerManagerCore

/// A status capsule shown on the top-ranked row of the bench section.
enum RowStatusBadge {
    case nextOn
}

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

/// One player's row on the Live screen: name, current stint or rested
/// time, game total, and goal time, in either the field or bench section.
/// Purely presentational; the containing view attaches the tap gesture,
/// computes `readiness`, and owns selection state.
struct PlayerRow: View {
    let name: String
    let stats: PlayerStats
    var isOnField: Bool = false
    var isKeeper: Bool = false
    var readiness: Readiness? = nil
    var statusBadge: RowStatusBadge? = nil
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.title2.weight(.semibold))
                        .lineLimit(1)
                    if isKeeper {
                        badge("GK", color: .algeriaGreen)
                    }
                    if readiness?.isDue == true {
                        badge("DUE", color: .algeriaRed)
                    }
                    if statusBadge == .nextOn {
                        badge("NEXT ON", color: .algeriaGreen)
                    }
                }
                if let readiness {
                    ReadinessBar(readiness: readiness)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                if let secondaryTimeText {
                    Text(secondaryTimeText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(totalMinutesValue)")
                        .font(.title3.bold())
                        .monospacedDigit()
                    Text("min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if stats.keeperSeconds > 0 {
                    Text("GK \(formatMinutes(stats.keeperSeconds))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(minHeight: 40)
        .contentShape(Rectangle())
        .background(rowBackground)
    }

    /// The game total in whole minutes, as a bare number for the large
    /// trailing figure (its "min" unit renders separately, right beside
    /// it).
    private var totalMinutesValue: Int {
        Int((stats.fieldSeconds / 60).rounded())
    }

    /// The current on-field stint, or the rested time on the bench,
    /// whichever applies to this row, formatted as `m:ss`. Nil only if the
    /// engine has no stats for this player at all.
    private var secondaryTimeText: String? {
        let seconds = isOnField ? stats.currentStintSeconds : stats.currentBenchStintSeconds
        guard let seconds else { return nil }
        return formatClock(seconds)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
            .foregroundStyle(.white)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.algeriaGreen.opacity(0.1) : Color.clear)
            )
            .overlay(alignment: .leading) {
                if isKeeper {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.algeriaGreen)
                        .frame(width: 4)
                        .padding(.vertical, 8)
                        .padding(.leading, 3)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.algeriaGreen : Color.clear, lineWidth: 3)
            )
    }
}

/// The thin readiness progress bar shown under an outfield row's name.
private struct ReadinessBar: View {
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

/// An empty field or keeper slot, tappable the same way a `PlayerRow` is.
struct PlaceholderSlotRow: View {
    let label: String
    var isSelected: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 46)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.algeriaGreen.opacity(0.1) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.algeriaGreen : Color.clear, lineWidth: 3)
                )
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        PlayerRow(
            name: "Ash",
            stats: PlayerStats(fieldSeconds: 720, keeperSeconds: 300, keeperStints: 1, currentStintSeconds: 120),
            isOnField: true,
            isKeeper: true
        )
        PlayerRow(
            name: "Blake",
            stats: PlayerStats(fieldSeconds: 900, currentStintSeconds: 310),
            isOnField: true,
            readiness: Readiness(ratio: 310 / 300, showsUrgency: true),
            isSelected: true
        )
        PlayerRow(
            name: "Casey",
            stats: PlayerStats(fieldSeconds: 500, currentStintSeconds: 200),
            isOnField: true,
            readiness: Readiness(ratio: 200 / 300, showsUrgency: true)
        )
        PlayerRow(
            name: "Drew",
            stats: PlayerStats(fieldSeconds: 120, benchSeconds: 780, currentBenchStintSeconds: 90),
            readiness: Readiness(ratio: 90 / 300, showsUrgency: false),
            statusBadge: .nextOn
        )
        PlaceholderSlotRow(label: "Empty slot")
    }
    .padding()
    .background(Color(.systemGray6))
}
