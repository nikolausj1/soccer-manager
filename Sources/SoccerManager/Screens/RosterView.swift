import SwiftUI
import SwiftData

/// The editable list of active players: add, rename, and archive.
struct RosterView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<PlayerRecord> { !$0.isArchived }, sort: \PlayerRecord.sortOrder)
    private var players: [PlayerRecord]

    @State private var editingPlayer: PlayerRecord?
    @State private var isAddingPlayer = false
    @State private var draftName = ""

    @AppStorage(AppSettings.halfLengthMinutesKey)
    private var halfLengthMinutes = AppSettings.defaultHalfLengthMinutes
    @AppStorage(AppSettings.shiftLengthMinutesKey)
    private var shiftLengthMinutes = AppSettings.defaultShiftLengthMinutes

    var body: some View {
        NavigationStack {
            Group {
                if players.isEmpty {
                    ContentUnavailableView {
                        Label("Add your players.", systemImage: "person.3")
                    } actions: {
                        Button("Add Player") { startAdding() }
                    }
                } else {
                    List {
                        Section {
                            ForEach(players) { player in
                                Text(player.name)
                                    .font(.title3)
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture { startEditing(player) }
                                    .swipeActions {
                                        Button("Archive") {
                                            player.isArchived = true
                                            try? context.save()
                                        }
                                        .tint(.orange)
                                    }
                            }
                        }
                        Section("Settings") {
                            Stepper(
                                "Half length: \(halfLengthMinutes) min",
                                value: $halfLengthMinutes,
                                in: 5...45,
                                step: 5
                            )
                            Stepper(
                                "Shift length: \(shiftLengthMinutes) min",
                                value: $shiftLengthMinutes,
                                in: 1...15,
                                step: 1
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Roster")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        startAdding()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingPlayer) {
                PlayerNameSheet(title: "Add Player", name: $draftName, onSave: addPlayer)
            }
            .sheet(item: $editingPlayer) { player in
                PlayerNameSheet(title: "Rename Player", name: $draftName) {
                    rename(player)
                }
            }
        }
    }

    private func startAdding() {
        draftName = ""
        isAddingPlayer = true
    }

    private func startEditing(_ player: PlayerRecord) {
        draftName = player.name
        editingPlayer = player
    }

    private func addPlayer() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (players.map(\.sortOrder).max() ?? -1) + 1
        let player = PlayerRecord(name: trimmed, sortOrder: nextOrder)
        context.insert(player)
        try? context.save()
        isAddingPlayer = false
    }

    private func rename(_ player: PlayerRecord) {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        player.name = trimmed
        try? context.save()
        editingPlayer = nil
    }
}

/// A small sheet with a single text field, used to add or rename a player.
private struct PlayerNameSheet: View {
    let title: String
    @Binding var name: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(onSave)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.height(180)])
    }
}

#Preview {
    RosterView()
        .modelContainer(for: [PlayerRecord.self, GameRecord.self, GameEventRecord.self], inMemory: true)
}
