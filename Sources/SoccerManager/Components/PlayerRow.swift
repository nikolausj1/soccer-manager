import SwiftUI
import SoccerManagerCore

/// A status capsule shown on the top-ranked row of a section.
enum RowStatusBadge {
    case nextOff
    case nextOn
}

/// One player's row on the Live screen: name, current stint, game total,
/// and goal time, in either the field or bench section. Purely
/// presentational; the containing view attaches the tap gesture and owns
/// selection state.
struct PlayerRow: View {
    let name: String
    let stats: PlayerStats
    var isOnField: Bool = false
    var isKeeper: Bool = false
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
                }
                if let statusBadge {
                    switch statusBadge {
                    case .nextOff:
                        badge("NEXT OFF", color: .algeriaRed)
                    case .nextOn:
                        badge("NEXT ON", color: .algeriaGreen)
                    }
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                if isOnField, let stint = stats.currentStintSeconds {
                    Text(formatClock(stint))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(formatMinutes(stats.fieldSeconds))
                    .font(.body.bold().monospacedDigit())
                if stats.keeperSeconds > 0 {
                    Text("GK \(formatMinutes(stats.keeperSeconds))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
        .background(rowBackground)
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
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
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
        .frame(minHeight: 52)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        PlayerRow(
            name: "Player A",
            stats: PlayerStats(fieldSeconds: 720, keeperSeconds: 300, keeperStints: 1, currentStintSeconds: 120),
            isOnField: true,
            isKeeper: true
        )
        PlayerRow(
            name: "Player B",
            stats: PlayerStats(fieldSeconds: 900, currentStintSeconds: 300),
            isOnField: true,
            statusBadge: .nextOff,
            isSelected: true
        )
        PlayerRow(
            name: "Player C",
            stats: PlayerStats(fieldSeconds: 120, benchSeconds: 780),
            statusBadge: .nextOn
        )
        PlaceholderSlotRow(label: "Empty slot")
    }
    .padding()
}
