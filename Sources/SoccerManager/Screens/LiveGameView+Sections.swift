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
            sectionHeader("Field")
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
                        readiness: readiness(for: id, in: snapshot),
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
                HStack {
                    sectionHeader("Bench", color: selected == .benchHeader ? Color.algeriaGreen : .secondary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } content: {
            ForEach(Array(snapshot.rankedBench.enumerated()), id: \.element) { index, id in
                rowButton(.player(id), snapshot: snapshot) {
                    PlayerRow(
                        name: names[id] ?? "Unknown",
                        stats: snapshot.stats[id] ?? PlayerStats(),
                        statusBadge: index == 0 ? .nextOn : nil,
                        isSelected: selected == .player(id)
                    )
                }
            }
        }
    }

    /// This player's stint measured against the configured shift length,
    /// for the readiness bar under their field row.
    private func readiness(for id: UUID, in snapshot: GameSnapshot) -> Readiness {
        let stint = snapshot.stats[id]?.currentStintSeconds ?? 0
        return Readiness(ratio: stint / shiftLengthSeconds)
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
