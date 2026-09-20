import SwiftUI
import SoccerManagerCore

/// A status capsule shown on the top-ranked row of the bench section.
enum RowStatusBadge {
    case nextOn
}

/// One player's row on the Live screen: name, current stint or rested
/// time, game total, and goal time, in either the field or bench section.
/// Purely presentational; the containing view attaches the tap gesture,
/// computes `readiness`, and owns selection state.
struct PlayerRow: View {
    /// The stint/rest column's fixed width, shared with the section
    /// header's "SHIFT"/"REST" caption (`LiveGameView+Sections.swift`) so
    /// the two line up.
    static let stintColumnWidth: CGFloat = 64
    /// The total-minutes column's fixed width, shared with the section
    /// header's "TOTAL" caption so the two line up.
    static let totalColumnWidth: CGFloat = 72

    let name: String
    let stats: PlayerStats
    var isOnField: Bool = false
    var isKeeper: Bool = false
    var readiness: Readiness? = nil
    var statusBadge: RowStatusBadge? = nil
    var isSelected: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Three fixed-width columns can't fit at accessibility
                // sizes without truncating. Stack instead: name and badges
                // on their own line, then the stint/rest and total columns
                // wrapped onto a second line below, sized to their content
                // rather than the normal layout's fixed widths.
                VStack(alignment: .leading, spacing: 4) {
                    nameAndBadges
                    if let readiness {
                        ReadinessBar(readiness: readiness)
                    }
                    HStack(spacing: 16) {
                        stintColumn
                        Spacer(minLength: 8)
                        totalColumn
                    }
                }
            } else {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        nameAndBadges
                        if let readiness {
                            ReadinessBar(readiness: readiness)
                        }
                    }
                    Spacer(minLength: 4)
                    stintColumn
                        .frame(width: Self.stintColumnWidth, alignment: .trailing)
                    totalColumn
                        .frame(width: Self.totalColumnWidth, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(minHeight: 40)
        .contentShape(Rectangle())
        .background(rowBackground)
    }

    private var nameAndBadges: some View {
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
    }

    /// The middle column: the current on-field stint, or the rested time
    /// on the bench, whichever applies to this row (the keeper row shows
    /// its own stint here like everyone else on the field).
    private var stintColumn: some View {
        Group {
            if let secondaryTimeText {
                Text(secondaryTimeText)
            }
        }
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }

    /// The far-right column: the game total, with the keeper's goal time
    /// underneath when nonzero.
    private var totalColumn: some View {
        VStack(alignment: .trailing, spacing: 1) {
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
