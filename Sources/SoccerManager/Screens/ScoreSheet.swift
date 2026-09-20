import SwiftUI
import SwiftData

/// The small sheet offered right after a game is saved, for optionally
/// recording the final score. Both "Save" and "Skip" dismiss the sheet;
/// `LiveGameView` shows the game's Summary either way once it is gone.
struct ScoreSheet: View {
    let game: GameRecord

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var ourScore = 0
    @State private var theirScore = 0

    private var store: GameStore { GameStore(context: context) }

    var body: some View {
        NavigationStack {
            Form {
                Stepper(value: $ourScore, in: 0...30) {
                    scoreRow(label: TeamConfig.name, score: ourScore)
                }
                Stepper(value: $theirScore, in: 0...30) {
                    scoreRow(label: "Opponent", score: theirScore)
                }
            }
            .navigationTitle("Final Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setScore(ourScore: ourScore, theirScore: theirScore, for: game)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(240)])
    }

    private func scoreRow(label: String, score: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(score)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ScoreSheet(game: GameRecord(attendance: []))
        .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
