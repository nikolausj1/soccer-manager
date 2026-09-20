import SwiftUI
import SoccerManagerCore

/// The field and bench sections of the Live screen: each a tinted, rounded
/// group of white row cards. Rows are already ordered by the engine
/// (`rankedOutfield` longest stint first, `rankedBench` longest rested
/// first), so no further sorting happens here.
extension LiveGameView {
    /// The keeper slot, then every ranked outfield player, then any empty
    /// field slots, on a card tinted Algeria green.
    func fieldSection(snapshot: GameSnapshot, names: [UUID: String]) -> some View {
        LiveSectionCard(backgroundColor: Color.algeriaGreen.opacity(0.06)) {
            HStack(spacing: 12) {
                sectionHeader("Field")
                Spacer()
                ColumnCaptions(middle: "Shift", right: "Total")
            }
            .padding(.trailing, columnCaptionTrailingCompensation)
        } content: {
            if let keeper = snapshot.keeper {
                rowButton(.player(keeper), snapshot: snapshot) {
                    PlayerRow(
                        name: names[keeper] ?? "Unknown",
                        stats: snapshot.stats[keeper] ?? PlayerStats(),
                        isOnField: true,
                        isKeeper: true,
                        isSelected: selected == .player(keeper)
                    )
                }
            } else {
                rowButton(.keeperSlot, snapshot: snapshot) {
                    PlaceholderSlotRow(label: "No keeper", isSelected: selected == .keeperSlot)
                }
            }

            ForEach(snapshot.rankedOutfield, id: \.self) { id in
                rowButton(.player(id), snapshot: snapshot) {
                    PlayerRow(
                        name: names[id] ?? "Unknown",
                        stats: snapshot.stats[id] ?? PlayerStats(),
                        isOnField: true,
                        readiness: outfieldReadiness(for: id, in: snapshot),
                        isSelected: selected == .player(id)
                    )
                }
            }

            // The field holds `fieldSize` total including the keeper, so an
            // empty keeper slot (the "No keeper" row above) already
            // accounts for one of those slots and must not also count as
            // an empty outfield slot.
            let emptySlots = max(
                0,
                TeamConfig.fieldSize - snapshot.onField.count - (snapshot.keeper == nil ? 1 : 0)
            )
            ForEach(0..<emptySlots, id: \.self) { _ in
                rowButton(.emptySlot, snapshot: snapshot) {
                    PlaceholderSlotRow(label: "Empty slot", isSelected: selected == .emptySlot)
                }
            }
        }
    }

    /// Every ranked bench player, under a title that doubles as the "send
    /// this field player to the bench" target, on a light gray card.
    func benchSection(snapshot: GameSnapshot, names: [UUID: String]) -> some View {
        LiveSectionCard(backgroundColor: Color(.systemGray6)) {
            Button {
                select(.benchHeader, in: snapshot, now: .now)
            } label: {
                HStack(spacing: 12) {
                    sectionHeader("Bench", color: selected == .benchHeader ? Color.algeriaGreen : .secondary)
                    Spacer()
                    ColumnCaptions(middle: "Rest", right: "Total")
                }
                .padding(.trailing, columnCaptionTrailingCompensation)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } content: {
            ForEach(Array(snapshot.rankedBench.enumerated()), id: \.element) { index, id in
                rowButton(.player(id), snapshot: snapshot) {
                    PlayerRow(
                        name: names[id] ?? "Unknown",
                        stats: snapshot.stats[id] ?? PlayerStats(),
                        readiness: benchReadiness(for: id, in: snapshot),
                        statusBadge: index == 0 ? .nextOn : nil,
                        isSelected: selected == .player(id)
                    )
                }
            }
        }
    }

    /// This player's current stint measured against the configured shift
    /// length, for the readiness bar under their field row: green under
    /// 0.6, amber to 1.0, red (and DUE) at or past it.
    private func outfieldReadiness(for id: UUID, in snapshot: GameSnapshot) -> Readiness {
        let stint = snapshot.stats[id]?.currentStintSeconds ?? 0
        return Readiness(ratio: stint / shiftLengthSeconds, showsUrgency: true)
    }

    /// This player's rested time measured against the configured shift
    /// length, for the meter under their bench row: always green, since
    /// rest is never urgent the way an overdue stint is.
    private func benchReadiness(for id: UUID, in snapshot: GameSnapshot) -> Readiness {
        let rested = snapshot.stats[id]?.currentBenchStintSeconds ?? 0
        return Readiness(ratio: rested / shiftLengthSeconds, showsUrgency: false)
    }

    /// `LiveSectionCard`'s title only gets 2pt of its own horizontal
    /// padding on top of the card's shared 8pt inset, while a `PlayerRow`
    /// below it adds a full 12pt of its own; this closes that 10pt gap so
    /// the column captions land directly above `PlayerRow`'s columns.
    private var columnCaptionTrailingCompensation: CGFloat { 10 }
}

/// The "SHIFT"/"REST" and "TOTAL" column captions, in the section header's
/// own caption-caps style, over `PlayerRow`'s matching fixed-width
/// columns. Hidden at accessibility text sizes: `PlayerRow` itself no
/// longer lays out in those two columns there (see its own accessibility
/// branch), and forcing this caption's text into the same fixed widths at
/// a much larger point size only breaks it mid-word.
private struct ColumnCaptions: View {
    let middle: String
    let right: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: 12) {
                caption(middle)
                    .frame(width: PlayerRow.stintColumnWidth, alignment: .trailing)
                caption(right)
                    .frame(width: PlayerRow.totalColumnWidth, alignment: .trailing)
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}

/// A section's rows, grouped in a tinted, rounded card under a title (which
/// may itself be an interactive view, as the bench section's is).
private struct LiveSectionCard<Title: View, Content: View>: View {
    let backgroundColor: Color
    @ViewBuilder let title: () -> Title
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            title()
                .padding(.horizontal, 2)
            VStack(spacing: 4) {
                content()
            }
        }
        .padding(8)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16))
    }
}
