import XCTest
@testable import SoccerManagerCore

/// Tests for `GameEngine`. Every event timestamp is a fixed offset from a
/// constant base date, never `Date()`, so results are exactly reproducible.
final class GameEngineTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func t(_ seconds: TimeInterval) -> Date {
        base.addingTimeInterval(seconds)
    }

    // MARK: - Start/stop accrual

    func testStartStopAccrual() {
        let p1 = UUID()
        let p2 = UUID()
        let keeper = UUID()
        let benchPlayer = UUID()
        let attendance = [p1, p2, keeper, benchPlayer]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1, p2, keeper], keeper: keeper),
            .clockStop(at: t(100), half: 1)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(500))

        XCTAssertFalse(snapshot.clockRunning)
        XCTAssertEqual(snapshot.elapsedTotal, 100)
        XCTAssertEqual(snapshot.stats[p1]?.fieldSeconds, 100)
        XCTAssertEqual(snapshot.stats[p2]?.fieldSeconds, 100)
        XCTAssertEqual(snapshot.stats[keeper]?.fieldSeconds, 100)
        // 400 seconds pass between the stop and `now`; none of it accrues.
        XCTAssertEqual(snapshot.stats[benchPlayer]?.benchSeconds, 100)
    }

    // MARK: - Swap while running

    func testSwapWhileRunningSplitsTimeCorrectly() {
        let p1 = UUID()
        let p2 = UUID()
        let p3 = UUID()
        let attendance = [p1, p2, p3]

        let baseEvents: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1, p2], keeper: nil)
        ]
        let beforeSwap = GameEngine.snapshot(events: baseEvents, attendance: attendance, now: t(100))
        let swapEvent = GameEngine.swap(snapshot: beforeSwap, off: p1, on: p3, at: t(100))
        let events = baseEvents + [swapEvent]

        let after = GameEngine.snapshot(events: events, attendance: attendance, now: t(250))

        // p1 played the first 100s only.
        XCTAssertEqual(after.stats[p1]?.fieldSeconds, 100)
        XCTAssertNil(after.stats[p1]?.currentStintSeconds)
        // p2 played the whole 250s without interruption.
        XCTAssertEqual(after.stats[p2]?.fieldSeconds, 250)
        XCTAssertEqual(after.stats[p2]?.currentStintSeconds, 250)
        // p3 came on at 100 and played the remaining 150s.
        XCTAssertEqual(after.stats[p3]?.fieldSeconds, 150)
        XCTAssertEqual(after.stats[p3]?.currentStintSeconds, 150)
        // The swap replaces p1's slot with p3.
        XCTAssertEqual(after.onField, [p3, p2])
    }

    // MARK: - Criterion 5: swap while stopped changes nobody's seconds

    func testSwapWhileStoppedChangesNobodysSeconds() {
        let p1 = UUID()
        let p2 = UUID()
        let p3 = UUID()
        let attendance = [p1, p2, p3]

        let baseEvents: [GameEvent] = [
            .lineup(at: t(0), half: 1, onField: [p1, p2], keeper: nil)
        ]
        let initial = GameEngine.snapshot(events: baseEvents, attendance: attendance, now: t(50))
        XCTAssertEqual(initial.stats[p1]?.fieldSeconds, 0)
        XCTAssertEqual(initial.stats[p2]?.fieldSeconds, 0)

        // The clock is never started anywhere in this test.
        let swapEvent = GameEngine.swap(snapshot: initial, off: p1, on: p3, at: t(50))
        let events = baseEvents + [swapEvent]
        let after = GameEngine.snapshot(events: events, attendance: attendance, now: t(100))

        XCTAssertFalse(after.clockRunning)
        XCTAssertEqual(after.stats[p1]?.fieldSeconds, 0)
        XCTAssertEqual(after.stats[p2]?.fieldSeconds, 0)
        XCTAssertEqual(after.stats[p3]?.fieldSeconds, 0)
        XCTAssertEqual(after.stats[p1]?.benchSeconds, 0)
        XCTAssertEqual(after.stats[p2]?.benchSeconds, 0)
        XCTAssertEqual(after.stats[p3]?.benchSeconds, 0)
    }

    // MARK: - Criterion 3: a long gap with no events advances timers exactly

    func testTenMinuteGapWithNoEventsWhileRunningAdvancesEveryOnFieldTimerByExactly600() {
        let p1 = UUID()
        let p2 = UUID()
        let benchPlayer = UUID()
        let attendance = [p1, p2, benchPlayer]

        let events: [GameEvent] = [
            .lineup(at: t(0), half: 1, onField: [p1, p2], keeper: nil),
            .clockStart(at: t(0), half: 1)
        ]

        // No further events for 600 seconds; `now` is the only thing that
        // closes the open interval.
        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(600))

        XCTAssertEqual(snapshot.stats[p1]?.fieldSeconds, 600)
        XCTAssertEqual(snapshot.stats[p2]?.fieldSeconds, 600)
        XCTAssertEqual(snapshot.stats[p1]?.currentStintSeconds, 600)
        XCTAssertEqual(snapshot.stats[benchPlayer]?.benchSeconds, 600)
        XCTAssertEqual(snapshot.elapsedTotal, 600)
        XCTAssertEqual(snapshot.elapsedInHalf, 600)
    }

    // MARK: - Keeper seconds included in field seconds

    func testKeeperSecondsAreIncludedInFieldSeconds() {
        let keeper = UUID()
        let p2 = UUID()
        let attendance = [keeper, p2]

        let events: [GameEvent] = [
            .lineup(at: t(0), half: 1, onField: [keeper, p2], keeper: keeper),
            .clockStart(at: t(0), half: 1)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(300))

        XCTAssertEqual(snapshot.stats[keeper]?.keeperSeconds, 300)
        XCTAssertEqual(snapshot.stats[keeper]?.fieldSeconds, 300)
        XCTAssertEqual(snapshot.stats[keeper]?.currentKeeperStintSeconds, 300)
        XCTAssertEqual(snapshot.stats[p2]?.fieldSeconds, 300)
        XCTAssertEqual(snapshot.stats[p2]?.keeperSeconds, 0)
    }

    // MARK: - Keeper stint counting

    func testKeeperStintCountsOnFirstLineup() {
        let keeper = UUID()
        let p2 = UUID()
        let attendance = [keeper, p2]

        // The pre-game lineup is set with the clock stopped, the same as
        // Justin does it on the sideline before kickoff.
        let snapshot = GameEngine.snapshot(
            events: [.lineup(at: t(0), half: 1, onField: [keeper, p2], keeper: keeper)],
            attendance: attendance,
            now: t(0)
        )

        XCTAssertEqual(snapshot.stats[keeper]?.keeperStints, 1)
        XCTAssertEqual(snapshot.stats[keeper]?.currentKeeperStintSeconds, 0)
        XCTAssertEqual(snapshot.stats[p2]?.keeperStints, 0)
    }

    func testKeeperStintCountsOnTradeKeeper() {
        let keeper1 = UUID()
        let keeper2 = UUID()
        let attendance = [keeper1, keeper2]

        let baseEvents: [GameEvent] = [
            .lineup(at: t(0), half: 1, onField: [keeper1, keeper2], keeper: keeper1)
        ]
        let initial = GameEngine.snapshot(events: baseEvents, attendance: attendance, now: t(0))
        XCTAssertEqual(initial.stats[keeper1]?.keeperStints, 1)

        let tradeEvent = GameEngine.tradeKeeper(snapshot: initial, newKeeper: keeper2, at: t(10))
        let after = GameEngine.snapshot(events: baseEvents + [tradeEvent], attendance: attendance, now: t(10))

        XCTAssertEqual(after.keeper, keeper2)
        XCTAssertEqual(after.stats[keeper2]?.keeperStints, 1)
        XCTAssertEqual(after.stats[keeper1]?.keeperStints, 1)
        XCTAssertNil(after.stats[keeper1]?.currentKeeperStintSeconds)
        XCTAssertEqual(after.stats[keeper2]?.currentKeeperStintSeconds, 0)
        // The outgoing keeper stays on the field as an outfield player.
        XCTAssertTrue(after.onField.contains(keeper1))
    }

    func testKeeperStintCountsWhenSwapSendsKeeperOff() {
        let keeper1 = UUID()
        let p2 = UUID()
        let benchPlayer = UUID()
        let attendance = [keeper1, p2, benchPlayer]

        let baseEvents: [GameEvent] = [
            .lineup(at: t(0), half: 1, onField: [keeper1, p2], keeper: keeper1)
        ]
        let initial = GameEngine.snapshot(events: baseEvents, attendance: attendance, now: t(0))

        let swapEvent = GameEngine.swap(snapshot: initial, off: keeper1, on: benchPlayer, at: t(20))
        let after = GameEngine.snapshot(events: baseEvents + [swapEvent], attendance: attendance, now: t(20))

        XCTAssertEqual(after.keeper, benchPlayer)
        XCTAssertEqual(after.stats[benchPlayer]?.keeperStints, 1)
        XCTAssertEqual(after.stats[benchPlayer]?.currentKeeperStintSeconds, 0)
        XCTAssertFalse(after.onField.contains(keeper1))
        XCTAssertNil(after.stats[keeper1]?.currentKeeperStintSeconds)
    }

    func testKeeperStintCountsOnEnterAsKeeper() {
        let keeper1 = UUID()
        let p2 = UUID()
        let benchPlayer = UUID()
        let attendance = [keeper1, p2, benchPlayer]

        let baseEvents: [GameEvent] = [
            .lineup(at: t(0), half: 1, onField: [keeper1, p2], keeper: keeper1)
        ]
        let initial = GameEngine.snapshot(events: baseEvents, attendance: attendance, now: t(0))

        let enterEvent = GameEngine.enter(snapshot: initial, player: benchPlayer, asKeeper: true, at: t(30))
        let after = GameEngine.snapshot(events: baseEvents + [enterEvent], attendance: attendance, now: t(30))

        XCTAssertEqual(after.keeper, benchPlayer)
        // Nobody left the field; the old keeper stays on as an outfielder.
        XCTAssertTrue(after.onField.contains(keeper1))
        XCTAssertTrue(after.onField.contains(benchPlayer))
        XCTAssertEqual(after.onField.count, 3)
        XCTAssertEqual(after.stats[benchPlayer]?.keeperStints, 1)
        XCTAssertNil(after.stats[keeper1]?.currentKeeperStintSeconds)
    }

    // MARK: - Undo

    func testRemovingLastLineupRestoresPreviousSnapshotExactly() {
        let p1 = UUID()
        let p2 = UUID()
        let p3 = UUID()
        let attendance = [p1, p2, p3]

        let baseEvents: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1, p2], keeper: nil)
        ]
        let before = GameEngine.snapshot(events: baseEvents, attendance: attendance, now: t(200))
        XCTAssertTrue(before.canUndo)

        let swapEvent = GameEngine.swap(snapshot: before, off: p1, on: p3, at: t(200))
        let withSwap = baseEvents + [swapEvent]

        let undone = GameEngine.removingLastLineup(withSwap)
        XCTAssertEqual(undone, baseEvents)

        let restored = GameEngine.snapshot(events: undone, attendance: attendance, now: t(200))
        XCTAssertEqual(restored, before)

        // Undo with no lineup event to remove is a no-op, and canUndo is
        // false with an empty lineup history.
        let noLineupEvents: [GameEvent] = [.clockStart(at: t(0), half: 1)]
        XCTAssertEqual(GameEngine.removingLastLineup(noLineupEvents), noLineupEvents)
        XCTAssertFalse(GameEngine.snapshot(events: noLineupEvents, attendance: attendance, now: t(0)).canUndo)
    }

    // MARK: - Ranking

    func testRankedOutfieldSortsByFieldSecondsThenFallsBackToAttendanceOrder() {
        let a = UUID()
        let b = UUID()
        let c = UUID()
        let d = UUID()
        let attendance = [a, b, c, d]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [a, b, c], keeper: nil),
            // d joins later; nobody leaves.
            .lineup(at: t(100), half: 1, onField: [a, b, c, d], keeper: nil)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(200))

        // a, b, c are tied at 200s each and fall back to attendance order;
        // d has only 100s and ranks last.
        XCTAssertEqual(snapshot.rankedOutfield, [a, b, c, d])
        XCTAssertEqual(snapshot.nextOff, a)
        XCTAssertEqual(snapshot.stats[a]?.fieldSeconds, 200)
        XCTAssertEqual(snapshot.stats[d]?.fieldSeconds, 100)
    }

    func testRankedOutfieldTiebreaksOnCurrentStintSecondsWhenFieldSecondsTie() {
        let a = UUID()
        let b = UUID()
        let attendance = [a, b]

        // b plays straight through. a plays the first 70s, sits out the
        // stoppage (so the gap costs nobody any seconds), then returns for
        // a fresh 70s stint. Both end up with 140 field seconds, but only
        // b's current stint spans the whole 140.
        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [a, b], keeper: nil),
            .clockStop(at: t(70), half: 1),
            .lineup(at: t(70), half: 1, onField: [b], keeper: nil),
            .lineup(at: t(90), half: 1, onField: [a, b], keeper: nil),
            .clockStart(at: t(90), half: 1)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(160))

        XCTAssertEqual(snapshot.stats[a]?.fieldSeconds, 140)
        XCTAssertEqual(snapshot.stats[b]?.fieldSeconds, 140)
        XCTAssertEqual(snapshot.stats[a]?.currentStintSeconds, 70)
        XCTAssertEqual(snapshot.stats[b]?.currentStintSeconds, 140)
        XCTAssertEqual(snapshot.rankedOutfield, [b, a])
        XCTAssertEqual(snapshot.nextOff, b)
    }

    func testRankedBenchSortsByFieldSecondsAscendingThenAttendanceOrder() {
        // Within one game, every attending player's fieldSeconds plus
        // benchSeconds equals the game's shared elapsedTotal, because each
        // running second is credited to exactly one of the two buckets for
        // every player. A fieldSeconds tie therefore always implies a
        // benchSeconds tie too, so the benchSeconds-descending tiebreak can
        // never itself discriminate within a single game; this test
        // exercises the fallthrough to attendance order it produces, and
        // separately checks the complementary-partition invariant.
        let a = UUID()
        let b = UUID()
        let c = UUID()
        let attendance = [a, b, c]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [c], keeper: nil),
            .lineup(at: t(50), half: 1, onField: [], keeper: nil)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(100))

        XCTAssertEqual(snapshot.stats[a]?.fieldSeconds, 0)
        XCTAssertEqual(snapshot.stats[b]?.fieldSeconds, 0)
        XCTAssertEqual(snapshot.stats[c]?.fieldSeconds, 50)
        XCTAssertEqual(snapshot.stats[a]?.benchSeconds, 100)
        XCTAssertEqual(snapshot.stats[b]?.benchSeconds, 100)
        XCTAssertEqual(snapshot.stats[c]?.benchSeconds, 50)
        XCTAssertEqual(snapshot.rankedBench, [a, b, c])
        XCTAssertEqual(snapshot.nextOn, a)
        for player in attendance {
            let playerStats = snapshot.stats[player]
            XCTAssertEqual(
                (playerStats?.fieldSeconds ?? -1) + (playerStats?.benchSeconds ?? -1),
                snapshot.elapsedTotal
            )
        }
    }

    func testKeeperExcludedFromRankedOutfield() {
        let keeper = UUID()
        let p2 = UUID()
        let attendance = [keeper, p2]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [keeper, p2], keeper: keeper)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(50))

        XCTAssertFalse(snapshot.rankedOutfield.contains(keeper))
        XCTAssertEqual(snapshot.rankedOutfield, [p2])
        XCTAssertEqual(snapshot.nextOff, p2)
    }

    // MARK: - Halves

    func testElapsedInHalfResetsAcrossHalvesWhileElapsedTotalKeepsCounting() {
        let p1 = UUID()
        let attendance = [p1]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1], keeper: nil),
            .clockStop(at: t(1200), half: 1),
            .clockStart(at: t(1300), half: 2)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(1600))

        XCTAssertEqual(snapshot.currentHalf, 2)
        // Only half 2's running time: 1600 - 1300.
        XCTAssertEqual(snapshot.elapsedInHalf, 300)
        // Both halves: 1200 (half 1) + 300 (half 2 so far).
        XCTAssertEqual(snapshot.elapsedTotal, 1500)
        XCTAssertEqual(snapshot.stats[p1]?.fieldSeconds, 1500)
    }

    // MARK: - Ignored no-ops

    func testDoubleClockStartIgnored() {
        let p1 = UUID()
        let attendance = [p1]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1], keeper: nil),
            // Already running; must not reset the open interval.
            .clockStart(at: t(30), half: 1)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(100))

        XCTAssertTrue(snapshot.clockRunning)
        XCTAssertEqual(snapshot.elapsedTotal, 100)
        XCTAssertEqual(snapshot.stats[p1]?.fieldSeconds, 100)
    }

    func testDoubleClockStopIgnored() {
        let p1 = UUID()
        let attendance = [p1]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1], keeper: nil),
            .clockStop(at: t(50), half: 1),
            // Already stopped; must not affect anything.
            .clockStop(at: t(80), half: 1)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(200))

        XCTAssertFalse(snapshot.clockRunning)
        XCTAssertEqual(snapshot.elapsedTotal, 50)
        XCTAssertEqual(snapshot.stats[p1]?.fieldSeconds, 50)
    }

    // MARK: - Unknown UUIDs

    func testUnknownUUIDsInLineupIgnored() {
        let p1 = UUID()
        let stranger = UUID()
        let attendance = [p1]

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1, stranger], keeper: stranger)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(60))

        XCTAssertEqual(snapshot.onField, [p1])
        XCTAssertNil(snapshot.keeper)
        XCTAssertNil(snapshot.stats[stranger])
        XCTAssertEqual(snapshot.stats[p1]?.fieldSeconds, 60)
    }

    func testKeeperNotListedOnFieldIsIgnored() {
        let p1 = UUID()
        let p2 = UUID()
        let attendance = [p1, p2]

        // Malformed on purpose: p2 is named keeper but not included on the
        // field. The engine defends the documented invariant instead of
        // trusting the event.
        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [p1], keeper: p2)
        ]

        let snapshot = GameEngine.snapshot(events: events, attendance: attendance, now: t(40))

        XCTAssertNil(snapshot.keeper)
        XCTAssertEqual(snapshot.stats[p2]?.keeperSeconds, 0)
        XCTAssertEqual(snapshot.stats[p2]?.keeperStints, 0)
    }
}
