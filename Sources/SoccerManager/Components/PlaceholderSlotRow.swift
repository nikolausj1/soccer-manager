import SwiftUI

/// An empty field or keeper slot, tappable the same way a `PlayerRow` is.
/// Keeps the same two trailing columns as `PlayerRow`, empty, so its
/// height and the section's column captions above it don't shift once the
/// slot is filled.
struct PlaceholderSlotRow: View {
    let label: String
    var isSelected: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
            Color.clear.frame(width: PlayerRow.stintColumnWidth)
            Color.clear.frame(width: PlayerRow.totalColumnWidth)
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
        PlaceholderSlotRow(label: "No keeper")
        PlaceholderSlotRow(label: "Empty slot", isSelected: true)
    }
    .padding()
    .background(Color(.systemGray6))
}
