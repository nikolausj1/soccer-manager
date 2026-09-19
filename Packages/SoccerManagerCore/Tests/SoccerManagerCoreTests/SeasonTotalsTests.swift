import XCTest
@testable import SoccerManagerCore

/// Tests for `SeasonTotals`. Every event timestamp is a fixed offset from a
/// constant base date, never `Date()`, so results are exactly reproducible.
final class SeasonTotalsTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func t(_ seconds: TimeInterval) -> Date {
        base.addingTimeInterval(seconds)
    }

    // MARK: - Criterion 6: season totals equal the sum of saved games

    func testSeasonTotalsSumsEqualPerGameSnapshotSums() {
        let a = UUID()
        let b = UUID()
        let c = UUID()

        let game1Events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [a, b], keeper: a),
            .clockStop(at: t(600), half: 1)
        ]
        let game1Attendance = [a, b]
        let game1EndedAt = t(700)
        let game1Snapshot = GameEngine.snapshot(events: game1Events, attendance: game1Attendance, now: game1EndedAt)

        let game2Events: [GameEvent] = [
            .clockStart(at: t(1000), half: 1),
            // b attends game 2 but never takes the field.
            .lineup(at: t(1000), half: 1, onField: [a, c], keeper: c),
            .clockStop(at: t(1400), half: 1)
        ]
        let game2Attendance = [a, b, c]
        let game2EndedAt = t(1500)
        let game2Snapshot = GameEngine.snapshot(events: game2Events, attendance: game2Attendance, now: game2EndedAt)

        let games = [
            SeasonGame(attendance: game1Attendance, events: game1Events, endedAt: game1EndedAt),
            SeasonGame(attendance: game2Attendance, events: game2Events, endedAt: game2EndedAt)
        ]
        let totals = SeasonTotals.compute(games: games)

        // Cross-checks: season totals equal the sum of each game's own
        // snapshot, for every stat the two types share.
        XCTAssertEqual(totals[a]?.gamesPlayed, 2)
        XCTAssertEqual(
            totals[a]?.fieldSeconds,
            (game1Snapshot.stats[a]?.fieldSeconds ?? 0) + (game2Snapshot.stats[a]?.fieldSeconds ?? 0)
        )
        XCTAssertEqual(
            totals[a]?.keeperSeconds,
            (game1Snapshot.stats[a]?.keeperSeconds ?? 0) + (game2Snapshot.stats[a]?.keeperSeconds ?? 0)
        )
        XCTAssertEqual(
            totals[a]?.keeperStints,
            (game1Snapshot.stats[a]?.keeperStints ?? 0) + (game2Snapshot.stats[a]?.keeperStints ?? 0)
        )

        XCTAssertEqual(totals[b]?.gamesPlayed, 2)
        XCTAssertEqual(
            totals[b]?.fieldSeconds,
            (game1Snapshot.stats[b]?.fieldSeconds ?? 0) + (game2Snapshot.stats[b]?.fieldSeconds ?? 0)
        )

        XCTAssertEqual(totals[c]?.gamesPlayed, 1)
        XCTAssertEqual(totals[c]?.fieldSeconds, game2Snapshot.stats[c]?.fieldSeconds)
        XCTAssertEqual(totals[c]?.keeperSeconds, game2Snapshot.stats[c]?.keeperSeconds)

        // Concrete expected numbers, not just cross-checks against the
        // engine's own output.
        XCTAssertEqual(totals[a]?.fieldSeconds, 1000) // 600 (game 1) + 400 (game 2)
        XCTAssertEqual(totals[a]?.keeperSeconds, 600)  // keeper only in game 1
        XCTAssertEqual(totals[b]?.fieldSeconds, 600)   // on field, non-keeper, in game 1 only
        XCTAssertEqual(totals[c]?.fieldSeconds, 400)
        XCTAssertEqual(totals[c]?.keeperSeconds, 400)
        XCTAssertEqual(totals[c]?.keeperStints, 1)
    }

    // MARK: - Criterion 6: gamesPlayed counts attendance

    func testGamesPlayedCountsAttendanceEvenWithoutTakingTheField() {
        let benchWarmer = UUID()
        let starter = UUID()

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [starter], keeper: nil),
            .clockStop(at: t(300), half: 1)
        ]
        let attendance = [starter, benchWarmer]
        let endedAt = t(400)

        let games = [SeasonGame(attendance: attendance, events: events, endedAt: endedAt)]
        let totals = SeasonTotals.compute(games: games)

        XCTAssertEqual(totals[benchWarmer]?.gamesPlayed, 1)
        XCTAssertEqual(totals[benchWarmer]?.fieldSeconds, 0)
        XCTAssertEqual(totals[benchWarmer]?.keeperStints, 0)
        XCTAssertEqual(totals[starter]?.gamesPlayed, 1)
        XCTAssertEqual(totals[starter]?.fieldSeconds, 300)
    }

    func testPlayerAbsentFromAllGamesHasNoEntry() {
        let attendee = UUID()
        let neverAttended = UUID()

        let events: [GameEvent] = [
            .clockStart(at: t(0), half: 1),
            .lineup(at: t(0), half: 1, onField: [attendee], keeper: nil),
            .clockStop(at: t(100), half: 1)
        ]
        let games = [SeasonGame(attendance: [attendee], events: events, endedAt: t(100))]
        let totals = SeasonTotals.compute(games: games)

        XCTAssertNotNil(totals[attendee])
        XCTAssertNil(totals[neverAttended])
    }

    func testMultipleGamesAccumulateAcrossGamesForTheSamePlayer() {
        let player = UUID()

        func game(startOffset: TimeInterval, duration: TimeInterval) -> SeasonGame {
            let events: [GameEvent] = [
                .clockStart(at: t(startOffset), half: 1),
                .lineup(at: t(startOffset), half: 1, onField: [player], keeper: player),
                .clockStop(at: t(startOffset + duration), half: 1)
            ]
            return SeasonGame(attendance: [player], events: events, endedAt: t(startOffset + duration))
        }

        let games = [
            game(startOffset: 0, duration: 200),
            game(startOffset: 10_000, duration: 300),
            game(startOffset: 20_000, duration: 500)
        ]

        let totals = SeasonTotals.compute(games: games)

        XCTAssertEqual(totals[player]?.gamesPlayed, 3)
        XCTAssertEqual(totals[player]?.fieldSeconds, 1000)
        XCTAssertEqual(totals[player]?.keeperSeconds, 1000)
        XCTAssertEqual(totals[player]?.keeperStints, 3)
    }
}
