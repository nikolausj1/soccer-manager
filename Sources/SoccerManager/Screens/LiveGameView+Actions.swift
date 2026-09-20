import Foundation
import SoccerManagerCore

/// Where a player currently stands relative to the game, used only to
/// resolve which engine action a pair of taps means.
enum PlayerRole {
    case keeper
    case fieldOutfield
    case bench
}

/// The engine call a resolved pair of taps maps to.
enum EngineAction {
    case swap(off: UUID, on: UUID)
    case tradeKeeper(newKeeper: UUID)
    case enter(player: UUID, asKeeper: Bool)
    case leave(player: UUID)
}

extension LiveGameView {
    func role(of id: UUID, in snapshot: GameSnapshot) -> PlayerRole {
        if id == snapshot.keeper { return .keeper }
        if snapshot.onField.contains(id) { return .fieldOutfield }
        return .bench
    }

    /// Handles a tap on `target`: starts a new selection, completes a
    /// two-tap action, deselects a repeated tap, replaces a pending
    /// same-kind selection, or ignores an illegal pairing. Order-invariant:
    /// swapping which of the two rows was tapped first never changes the
    /// result.
    func select(_ target: Selection, in snapshot: GameSnapshot, now: Date) {
        guard let current = selected else {
            selected = target
            return
        }
        if current == target {
            selected = nil
            return
        }
        if let action = resolvedAction(current, target, snapshot: snapshot) {
            perform(action, snapshot: snapshot, now: now)
            return
        }
        if shouldReplaceSelection(current, target, snapshot: snapshot) {
            selected = target
        }
        // Otherwise the pairing is illegal: ignore it, keep the first
        // selection as it was.
    }

    /// The action a pair of selections resolves to, independent of which
    /// one was tapped first, or nil if the pair is not a recognized action.
    private func resolvedAction(_ x: Selection, _ y: Selection, snapshot: GameSnapshot) -> EngineAction? {
        if case .player(let a) = x, case .player(let b) = y {
            switch (role(of: a, in: snapshot), role(of: b, in: snapshot)) {
            case (.bench, .fieldOutfield): return .swap(off: b, on: a)
            case (.fieldOutfield, .bench): return .swap(off: a, on: b)
            case (.bench, .keeper): return .swap(off: b, on: a)
            case (.keeper, .bench): return .swap(off: a, on: b)
            case (.fieldOutfield, .keeper): return .tradeKeeper(newKeeper: a)
            case (.keeper, .fieldOutfield): return .tradeKeeper(newKeeper: b)
            default: return nil
            }
        }

        guard let (playerID, other) = pullPlayer(x, y) else { return nil }
        let playerRole = role(of: playerID, in: snapshot)

        switch other {
        case .emptySlot:
            return playerRole == .bench ? .enter(player: playerID, asKeeper: false) : nil
        case .keeperSlot:
            if playerRole == .bench { return .enter(player: playerID, asKeeper: true) }
            if playerRole == .fieldOutfield { return .tradeKeeper(newKeeper: playerID) }
            return nil
        case .benchHeader:
            return (playerRole == .fieldOutfield || playerRole == .keeper) ? .leave(player: playerID) : nil
        case .player:
            return nil // handled above
        }
    }

    /// "Two bench players, or two outfield players: the second replaces the
    /// first as the selection."
    private func shouldReplaceSelection(_ x: Selection, _ y: Selection, snapshot: GameSnapshot) -> Bool {
        guard case .player(let a) = x, case .player(let b) = y else { return false }
        let roleA = role(of: a, in: snapshot)
        let roleB = role(of: b, in: snapshot)
        return (roleA == .bench && roleB == .bench) || (roleA == .fieldOutfield && roleB == .fieldOutfield)
    }

    /// Pulls the `.player` id out of a pair where exactly one side is a
    /// player, returning it with the other selection, regardless of order.
    private func pullPlayer(_ x: Selection, _ y: Selection) -> (UUID, Selection)? {
        if case .player(let id) = x { return (id, y) }
        if case .player(let id) = y { return (id, x) }
        return nil
    }

    private func perform(_ action: EngineAction, snapshot: GameSnapshot, now: Date) {
        let event: GameEvent
        switch action {
        case .swap(let off, let on):
            event = GameEngine.swap(snapshot: snapshot, off: off, on: on, at: now)
        case .tradeKeeper(let newKeeper):
            event = GameEngine.tradeKeeper(snapshot: snapshot, newKeeper: newKeeper, at: now)
        case .enter(let player, let asKeeper):
            event = GameEngine.enter(snapshot: snapshot, player: player, asKeeper: asKeeper, at: now)
        case .leave(let player):
            event = GameEngine.leave(snapshot: snapshot, player: player, at: now)
        }
        store.append(event, to: game)
        selected = nil
    }

    /// Appends the `clockStart` event that begins `half`: the kickoff
    /// pill starts half 1, the halftime pill starts half 2. Ending a half
    /// or the game appends its own `clockStop` directly in
    /// `LiveGameView+Footer.swift`, next to the alert that triggers it.
    func startHalf(_ half: Int, now: Date) {
        store.append(.clockStart(at: now, half: half), to: game)
    }

    /// Describes what the Undo button will do, per the Live screen's
    /// labeling rules: a one-for-one swap names both players, a
    /// keeper-only change names who it will remove from goal, and anything
    /// else falls back to a generic label.
    func undoLabel(snapshot: GameSnapshot, names: [UUID: String], now: Date) -> String {
        let events = game.events.map(\.event)
        let reduced = GameEngine.removingLastLineup(events)
        guard reduced.count < events.count else { return "Undo last change" }
        let before = GameEngine.snapshot(events: reduced, attendance: game.attendance, now: now)

        let onFieldBefore = Set(before.onField)
        let onFieldAfter = Set(snapshot.onField)
        let cameOn = onFieldAfter.subtracting(onFieldBefore)
        let wentOff = onFieldBefore.subtracting(onFieldAfter)

        if cameOn.count == 1, wentOff.count == 1, let on = cameOn.first, let off = wentOff.first {
            return "Undo: \(names[on] ?? "Unknown") for \(names[off] ?? "Unknown")"
        }
        if cameOn.isEmpty, wentOff.isEmpty, before.keeper != snapshot.keeper, let keeper = snapshot.keeper {
            return "Undo: \(names[keeper] ?? "Unknown") in goal"
        }
        return "Undo last change"
    }
}
