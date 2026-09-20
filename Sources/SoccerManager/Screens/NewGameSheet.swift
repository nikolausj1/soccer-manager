import SwiftUI
import SwiftData

/// The attendance checklist shown before a new game starts. Every active
/// player is checked by default; Start is disabled with nobody checked.
struct NewGameSheet: View {
    /// Called with the newly created game right before the sheet
    /// dismisses, so the caller can push it onto its navigation path.
    var onCreate: (GameRecord) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<PlayerRecord> { !$0.isArchived }, sort: \PlayerRecord.sortOrder)
    private var players: [PlayerRecord]

    @State private var checked: Set<UUID> = []
    @State private var hasInitializedChecklist = false

    var body: some View {
        NavigationStack {
            List(players) { player in
                Button {
                    toggle(player.id)
                } label: {
                    HStack {
                        Text(player.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: checked.contains(player.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(checked.contains(player.id) ? Color.algeriaGreen : .secondary)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start", action: start)
                        .disabled(checked.isEmpty)
                }
            }
            .onAppear {
                guard !hasInitializedChecklist else { return }
                hasInitializedChecklist = true
                checked = Set(players.map(\.id))
            }
        }
    }

    private func toggle(_ id: UUID) {
        if checked.contains(id) {
            checked.remove(id)
        } else {
            checked.insert(id)
        }
    }

    private func start() {
        let attendance = players.map(\.id).filter { checked.contains($0) }
        let game = GameRecord(attendance: attendance)
        context.insert(game)
        try? context.save()
        onCreate(game)
        dismiss()
    }
}

#Preview {
    NewGameSheet()
        .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
