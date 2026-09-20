---
title: "Soccer Manager - Product Requirements Document"
created: 2026-09-19
modified: 2026-09-19
version: 1.2.1
author: Claude Fable 5.1 (claude-fable-5-1)
tags:
---

# Soccer Manager - Product Requirements Document

| | |
|---|---|
| **Product** | Soccer Manager, a sideline substitution tracker that keeps playing time even |
| **Platform** | iOS |
| **Status** | v1.2 PRD - revised 2026-09-19 after the second v1.1 hands-on |
| **Companion docs** | `Project Build Guide.md` (accounts, stack, deployment - follow it, do not restate it) |

## Revision Notes

**2026-09-19 (v1.2):** Justin's second hands-on, this time with v1.1, the same day.

- **Bench rows now carry the same rest meter as outfield rows.** He wanted the meter for bench kids too, not just the field.
- **Start/Stop and the half picker are gone, replaced by a whistle-driven flow: Start 1st half, End Half, Start 2nd half, End Game, each confirmed by an alert.** The big Stop button was unnecessary, and an end must never be a single accidental tap.
- **No pause; an injury stoppage now runs on the clock.** A lead's call, stated to him rather than asked.
- **The game date joins the team name in the header.**
- **The live game is a pushed screen with a Back button and no tab bar,** so leaving it is a deliberate act, not a stray tab tap.
- **Discard moved to swipe-to-delete in the games list, which now also lists the in-progress game** as its top row.

**2026-09-19 (v1.1):** Justin's first hands-on with v1.0, shipped the same day.

- **Half timer now counts down; player and bench timers still count up.** He wants time left in the half at a glance.
- **"Next off" replaced by a readiness scale shown for every field player.** He runs five-minute shifts, so the flag was landing on the kid who had just come on; the scale also lets him override it for an injury or a behavior call.
- **Half length and shift length became settings.** His games do not all run the same lengths.
- **Delete a finished game and discard an in-progress game were added.** He is testing the app and needs to clear out games that were not real.
- **An optional final score was added.** Nice to have on the record, never required.

## 1. Overview and Vision

Justin coaches a U8 5v5 recreational soccer team of eight kids by himself, no assistant, sideline only. His goal for every game is that the kids get roughly equal field time, including roughly equal turns in goal, which is the spot they all want. The problem is not deciding what "fair" looks like, it is holding that arithmetic in his head while he is also coaching the run of play. At a stoppage he has a few seconds to know who has been out longest, who is due on, and who has and has not had a turn in goal, then act on it before the whistle. Memory drifts within a half. A paper sheet cannot be read or written one-handed while watching eight seven-year-olds. Both fail at exactly the moment that matters: the stoppage.

Soccer Manager is a one-screen iPhone app that always shows, at a glance, who on the field has played the most and who on the bench has played the least, and lets Justin swap two kids in two taps.

This approach wins because it is not a general-purpose youth-sports app, it is a personal tool built to fit one specific sideline moment: phone normally in a pocket, pulled out one-handed, outdoors, for two seconds at a time. No existing app was tried and rejected for this project. The baseline it replaces is memory and paper, and the bar it has to clear is "faster and more reliable than either." Building it is also, by Justin's own account, part of the point.

## 2. Users

One user, always: Justin, the coach. Nobody else holds the phone in v1, there is no assistant-coach or parent role, and no hand-off design exists.

Justin's context while using the app:

- On the sideline of a U8 (7-year-old) 5v5 rec game, coaching alone.
- Phone is normally in his pocket. He takes it out only at stoppages, glances, and puts it back.
- Interaction is one-handed and outdoors: sun glare, possibly cold or wet hands, no time to hunt through menus.
- His attention is on the game, not the phone. The app has to win in two seconds or lose his attention back to the field.
- He already knows the game-day facts the app cannot infer (who is limping, who wants a break, who just conceded a goal) and remains the decision-maker. The app supplies arithmetic and memory, not judgment.

## 3. Goals and Success Criteria

**Goals:**

- Keep field time roughly even across the kids on the roster, without costing Justin any attention he needs for coaching.
- Make the goalkeeper rotation, the most coveted spot on the team, visibly fair over a season, not just a game.
- Hold up under real sideline conditions: a pocketed phone, a locked screen, a force-quit, without losing a second of tracked time.

**Success criteria:**

1. Next off and next on are visible for 8 kids with no scroll and no tap, portrait.
2. A swap is two taps and under 2 seconds from unlock. Undo is one tap.
3. Lock the phone 10 minutes mid-half: every running timer advanced 10:00 within 1 second.
4. Force-quit and relaunch mid-half: clock, lineup and every timer resume with no loss.
5. Swaps made while the clock is stopped change nobody's minutes.
6. Season totals equal the sum of saved games exactly.
7. Kids' real names appear nowhere in the repo or in review screenshots.

**The one-sentence test:** At a second-half stoppage, Justin glances, shouts two names, taps twice, and the phone is back in his pocket before the ball is back in play.

## 4. Scope

**In scope (v1):**

- Roster: names only, add, rename, archive (a soft remove that keeps season history).
- Attendance per game.
- Pre-game lineup: tap kids from the bench onto the field with the clock stopped, designate a keeper.
- Live screen: half and elapsed clock, ranked field and bench, next off and next on flagged, current stint and game total per kid, keeper marker with goal share.
- Tap-tap swap between any field and bench kid.
- Keeper change, the same gesture as a swap.
- Undo, one tap, reverses the most recent lineup change.
- Whistle-driven clock: Start 1st half, End Half, Start 2nd half, End Game, each end confirmed by an alert. No pause.
- End game, with a per-kid summary.
- Season totals screen.
- Screen stays awake while a game is live.
- Survives force-quit and relaunch mid-game with no data loss.
- Settings: half length and shift length, editable from Roster.
- Delete a finished game, with confirmation.
- Delete any game, including one in progress, by swiping it in the games list, with confirmation.
- Optional final score, entered after End Game.

**Out of scope (non-goals):**

- Alerts or buzzes when someone is due off. Justin decides when to look, the app never interrupts him. A "someone is due" buzz was rejected because it second-guesses the coach's own attention.
- Drag and drop for substitutions. Rejected as the worst one-handed, outdoor gesture available, in favor of tap-tap.
- A prescribed or auto-generated rotation schedule. Rejected as brittle, and because it fights the reality that Justin moves kids for reasons the app cannot see.
- Multi-team or multi-season UI. One team, one running season is the whole scope; anything more is complexity nobody uses.
- Sync or accounts. Everything lives on Justin's phone only; there is nothing to sign into and nothing to sync to in v1.
- Editing a finished game's history, or editing any past event beyond Undo. Late taps cost the delay; that cost is accepted against "roughly equal."
- Anything parent- or league-facing. Proof of playing time for parents or a league is explicitly not a goal, even though a per-game record exists as a byproduct.
- Positions, formations. Statistics beyond minutes, keeper stints and a final score remain out. None of these serve the even-minutes problem.
- Apple Watch. Deferred alongside the Live Activity it would pair with.
- Landscape orientation. Portrait only, to match a one-handed pocket-to-glance motion.

**Deferred (v1.1+ candidates), with target:**

- v1.1: a backdate-last-swap nudge for a late tap, only if Justin wants it after two or three real games.
- v1.2: a soft "half has passed 20:00" reminder. Never an auto-stop.
- v2: a lock-screen Live Activity showing half, elapsed, next off, next on, the only option that would shorten the glance below what unlocking the phone costs.
- v2: a "start new season" archive action.
- v3: iCloud sync, once surviving a lost or replaced phone outweighs the cost of touching every model to support it.

## 5. Product Principles

1. **Glance beats interaction.** The live screen has to answer "who's next" from layout, ranking, and color alone, with no tap required. Every design choice on the Live screen defers to the two-second glance.
2. **Undo beats confirm.** v1 keeps no edit history and asks no confirmation for a swap, because Justin's hands and attention are busy elsewhere. One tap of Undo recovers from a mistake faster than a confirmation dialog would have prevented one.
3. **Even is a ranking, not an alert.** The app never tells Justin someone is due, it only ever shows the order; readiness is shown for every field player, never a single flag. He decides when to look and when to act; the app supplies memory, not judgment.

## 6. Functional Requirements

Three tabs: **Game**, **Season**, **Roster**. Built in `SwiftUI` (locked). Every screen reads local `SwiftData` synchronously, so unless a screen says otherwise below, it has no loading state; and unless noted, it has no error state either, since a local on-device write either succeeds or the app has a bug, not something v1 designs a recovery flow for.

### Roster

Editable list of active players. Add a player by name. Rename in place. Archive via swipe; archived players are hidden from attendance but stay in season history. A Settings section at the bottom holds two steppers: half length (5 to 45 minutes, by 5) and shift length (1 to 15 minutes).

- Empty: no players yet. Shows "Add your players." and the add-player control. No game can be created until at least one player exists.

### Game tab

Always a list of games, most recent first, each row a date and a one-line summary, with a "New game" button. An in-progress game (any phase before `finished`) is always the top row, reading "In progress," its date, and its current phase. Tapping it pushes Live; tapping "New game" inserts a new in-progress row and pushes it the same way. The app also pushes the in-progress game automatically the first time the Game tab appears after launch. Every row, in progress or finished, can be swiped to delete, with a confirming alert; deleting a finished game recomputes season totals immediately to drop it.

- Empty: no games played yet. Shows an empty-state message and the "New game" button, nothing else.

### New game sheet

Attendance checklist over the active roster, every player checked by default. "Start" creates the game with every checked player on the bench, nobody on the field yet, and opens Live in the `kickoff` phase.

- Empty: if the roster itself is empty, the sheet cannot be reached; Roster's empty state governs instead.
- Error: zero players checked. "Start" is disabled until at least one player is checked; a game with an empty attendance list has nothing for the engine to rank.

### Live

Title: team name and game date, "Algeria · Sep 19." A pushed screen, not a tab: a Back button top left returns to the Game tab, and the tab bar is hidden while Live is on screen.

Header by phase: `kickoff` and `halftime` each show a label, a countdown at the full half length, and a green Start button ("Start 1st half" or "Start 2nd half"); `firstHalf` and `secondHalf` each show the countdown running down, with a subtitle. Past zero in a running half it reads "+m:ss" in red and keeps counting, never auto-stopping. Field section: keeper row first, stint and the `GK` badge, no bar; then outfield rows ordered longest current stint first, each with a readiness bar (fill is current stint divided by shift length: green under 60 percent, amber 60 to 100, red at or above 100 with a **DUE** badge), no **NEXT OFF** badge. Bench section: ranked least-played first, top row flagged **NEXT ON**, every row also showing a bar toward one shift length (fill only, green only, no amber, no red, no badge) plus rested time. Every row shows name, current stint, game total, and goal share if nonzero.

Selection model (locked, tap-tap swap): tap a row to select it, tap a second row to act, tap the same row again to deselect.

- Field player + bench player selected: they swap.
- Keeper + field player selected: roles trade.
- Keeper + bench player selected: the bench player enters in goal, the keeper goes to the bench.
- Bench player + an empty field slot selected: the bench player enters (covers fewer than 5 on the field).
- Field player selected + "To bench" header: that player leaves the field without a replacement.

Footer: Undo on the left, labeled with what it will undo, hidden when there is nothing to undo. The right button depends on phase: none at `kickoff`, "End Half" in `firstHalf`, "End Game" at `halftime` and in `secondHalf`, each behind a confirming alert whose confirm is the only way an end takes effect, so one accidental tap can never end a half or the game. Confirming "End Game" runs the optional Final score sheet (two steppers, Save or Skip), then the Summary. The screen is held awake (idle timer disabled) for as long as Live is on screen and the game is not `finished`.

- Empty: not reachable. Live is only ever pushed for a game that already exists; the Game tab's own empty state, above, covers having no game at all.
- Error: an action that is not currently legal (for example, no end-of-phase button is offered at `kickoff`, when there is nothing yet to end) is simply not offered rather than shown and rejected. See the edge case table below for the specific cases this covers.

### Summary

Shown immediately after End Game, and by tapping any past game from the Game tab's list. Per player for that game: field minutes, goal minutes, goal stints.

- Empty: not reachable. A game cannot be started with zero attendance (see New game sheet's error state), so a `Summary` always has at least one player to show.

### Season

Per active player: games played, field minutes, goal minutes, goal stints, sorted by goal stints ascending then goal minutes ascending, so the top row is whoever is most due for a turn in goal.

- Empty: no finished game yet. Shows an empty-state message; the tab has nothing to total.

### Game state machine

Five phases: `kickoff`, `firstHalf`, `halftime`, `secondHalf`, `finished`.

- **`kickoff`**: the game exists (created from the New Game sheet) but the clock has never started. Justin builds the initial lineup by tapping bench players onto field slots and designating a keeper; each tap-tap pair records a `lineup` snapshot event but nothing accrues time, since the clock has not run.
- **`firstHalf`**: the clock is running for half 1. Time accrues to whichever players are on the field. Lineup changes are allowed and take effect immediately; they record a `lineup` event but never a clock event.
- **`halftime`**: the first half has ended and the second has not started. Lineup changes are allowed and recorded, but accrue no time (success criterion 5).
- **`secondHalf`**: the clock is running for half 2, the same accrual rules as `firstHalf`.
- **`finished`**: "End Game" was confirmed. Terminal state; the game moves into season totals and the Summary is shown. Nothing in a `finished` game can be edited in v1; Undo only ever acts on a game that is not yet finished.

Transitions: `kickoff -> firstHalf` on "Start 1st half". `firstHalf -> halftime` on "End Half" confirmed in its alert. `halftime -> secondHalf` on "Start 2nd half". `halftime -> finished` or `secondHalf -> finished` on "End Game" confirmed in its alert, which records a final clock stop first if the clock is running. Lineup edits are allowed in every phase before `finished` and accrue time only while the clock is running, in `firstHalf` or `secondHalf`, without changing the phase itself. A game in any phase can also be deleted outright by swiping its row in the Game tab; that is a list action, not a phase transition.

### Edge cases

| Case | Behavior |
|---|---|
| End Half tapped by accident | Opens a confirming alert; choosing Cancel leaves the half running and records nothing. |
| End Game at halftime | Allowed: confirming the alert during `halftime` ends the game and saves it with only the first half played. |
| Injury stoppage | No pause in v1.2: the clock keeps running, so the stoppage counts toward whoever is on the field at the time. |
| App relaunched mid-game | The Game tab pushes the in-progress game's Live screen automatically the first time it appears after launch. |
| Back pressed mid-game | The game stays in progress as the Game tab's top row; every timer keeps running from stored timestamps, so nothing pauses or is lost. |
| Swap at halftime | A lineup snapshot event is recorded and the on-field/bench assignment changes immediately, but nobody's field seconds or bench seconds change, because no time accrues outside `firstHalf` or `secondHalf` (success criterion 5). |
| Keeper swap with bench player | Same tap-tap gesture as any swap: tap the keeper, tap a bench player. One `lineup` event records the bench player as the new keeper and the old keeper moves to the bench. A new keeper stint begins for the player entering goal. |
| Undo after clock stop | Undo always removes only the single most recent `lineup` event and restores the previous snapshot, whether the clock is currently running or stopped. It never touches `clockStart` or `clockStop` events. |
| Fewer than 5 present | No minimum is enforced. The field can hold any number of players, including an empty slot; an empty field slot is filled by selecting a bench player next (see Live's selection model). |
| Force-quit mid-half | On relaunch, the engine rebuilds the current `GameSnapshot` by replaying the full stored event log against the current time. If the log's last clock event was `clockStart`, the clock resumes running and every player's seconds reflect the full wall-clock gap; nothing is lost (success criterion 4). |
| App backgrounded 10 minutes | Time is derived from event timestamps and wall-clock `now` at snapshot time, never from an in-process timer. Backgrounding changes nothing about what is stored; on foreground, every running player's seconds include the full 10 minutes (success criterion 3). |
| Countdown reaches zero | Header turns red and counts up past zero as overtime ("+m:ss"); nothing stops automatically. |
| Kid just came on | Sorts to the bottom of the field order, empty green readiness bar, never flagged **DUE**. |
| Delete a finished game | Season totals recompute immediately and drop that game's minutes. |

## 7. Visual and Design Spec

Locked, from the interrogation, with the team-identity decision Justin made on 2026-09-19:

- The team is **Algeria**; the palette is the flag. Background is white, light mode first, no dark mode requirement for v1.
- Accent color and the **NEXT ON** highlight (top-ranked bench row): Algeria green `#006233`.
- Readiness bar under each outfield name: Algeria green `#006233` below 60 percent of the shift length, system amber from 60 to 100 percent, flag red `#D21034` at or above 100 percent with a red DUE badge. There is no NEXT OFF badge.
- The `GK` badge, wherever the keeper appears, is green (`#006233`).
- System fonts throughout, no custom typography.
- Player names render at least at title text size, the single most important legibility requirement given outdoor glare and a two-second glance.
- Each player row has three columns: name, badges and the readiness or rest bar on the left; the current shift or rest time (minutes and seconds) in a fixed-width middle column; the game total in whole minutes in a fixed-width far-right column, with the keeper's goal share as a caption under it. Section headers carry the column captions once (SHIFT and TOTAL on the field, REST and TOTAL on the bench).
- Strong contrast between text and background.
- Portrait only (locked), no landscape layout to design or test.
- The team name "Algeria" is shown as the Game tab's title. It lives in a single named constant in the app layer; unlike the kids' names, which stay out of the repo entirely (Section 9), the team name is not personal information and needs no gitignored fixture.
- App icon: green and white halves with a red soccer ball silhouette, generated by script (Section 10, Phase 4).

Placeholder names are used in every screenshot that leaves the simulator: in `_review/`, and anywhere else outside Justin's own phone. The `-seedRoster` launch argument seeds eight placeholder names for this purpose; `-autostartLiveGame` seeds a running game so a screenshot can be taken without manually driving the UI first.

No mockups exist yet; this section is the full visual spec until `_review/` screenshots refine it further (see the gap-from-even and half-length open questions in Section 12).

## 8. Data Model

The engine, `SoccerManagerCore` (a local Swift package, locked), owns this model in full. The app's `SwiftData` records exist only to persist it across launches; naming and shape mirror the engine one to one.

### GameEvent

A struct, and the only unit of history the engine stores: `id`, `at: Date`, `kind` (`clockStart`, `clockStop`, or `lineup`), `half: Int` (1 or 2, present on clock events), and `onField: [UUID]` plus `keeper: UUID?` (present on lineup events).

**Invariant (locked): a lineup event is a full snapshot**, not a diff. It records who is on the field and who is keeper after the change, in full, every time.

**Invariant (locked): Undo removes only the most recent lineup event.** Because every lineup event is a full snapshot, deleting the most recent one always exposes a valid, complete previous state; there is nothing else to reconcile and nothing else Undo needs to touch.

### GameSnapshot

The read model, computed fresh on demand by `GameEngine.snapshot(events:, attendance:, now:) -> GameSnapshot`, never stored: `clockRunning`, `currentHalf`, `elapsedInHalf`, `elapsedTotal`, `onField`, `keeper`, `bench`, `rankedOutfield`, `rankedBench`, `nextOff`, `nextOn`, and a `PlayerStats` per player.

### PlayerStats

Per player, per game: `fieldSeconds`, `keeperSeconds`, `keeperStints`, `currentStintSeconds?`, `currentKeeperStintSeconds?`, `benchSeconds`, `currentBenchStintSeconds?`. The last is `nil` while the player is on the field, resets to zero on leaving it, and accumulates only while the clock runs.

**Invariant (locked): time accrues only while the clock runs.** Seconds move only between a `clockStart` and the next `clockStop`, or up to `now` if the clock is currently running. Lineup changes recorded while the clock is stopped change nobody's seconds.

**Invariant: field seconds include keeper seconds.** Keeper time is a subset of field time, not additional to it; a keeper is never double-counted against a total-minutes figure.

Keeper stints increment by one on each lineup event where the keeper becomes a player who was not the keeper in the immediately previous snapshot; the first lineup event of the game that has a keeper at all counts as a stint too. Current stint resets to zero whenever a player enters the field, and accumulates only while the clock is running.

Ranking: outfield sorted by `currentStintSeconds` descending, tie broken by `fieldSeconds` descending, then by attendance order. Bench sorted by `fieldSeconds` ascending, tie broken by `currentBenchStintSeconds` descending, then attendance order. The keeper is never included in `rankedOutfield`. `nextOff` is the first ranked outfield player, `nextOn` is the first ranked bench player, both `nil` when their list is empty.

Half length and shift length are app settings (Roster, Section 6), never stored in the engine or a `GameEvent`. Readiness, including the DUE threshold, is computed in the app from `currentStintSeconds` and shift length, not by the engine.

### SeasonStats

`SeasonTotals.compute(games:) -> [UUID: SeasonStats]`, over `(attendance: [UUID], events: [GameEvent])` pairs, finished games only. Per player: `gamesPlayed`, `fieldSeconds`, `keeperSeconds`, `keeperStints`.

**Invariant: season totals equal the exact sum of the corresponding per-game totals** for every finished game (success criterion 6). There is no independent season ledger to drift out of sync.

### SwiftData persistence (locked)

Three record types persist this model, one to one, so the engine's pure functions can be re-run against stored data at any time with no migration:

- `PlayerRecord`: roster identity, name, active or archived. Source of truth for the `attendance` lists and for names, which never enter the engine.
- `GameRecord`: one per game, holding its date, its attendance (the `[UUID]` list the engine needs), whether it is `finished`, and optional `ourScore: Int?` and `theirScore: Int?`. Summary and Season both read finished `GameRecord`s.
- `GameEventRecord`: one row per `GameEvent`, append-only, persisting `id`, `at`, `kind`, `half`, `onField`, and `keeper` exactly as the engine defines them. Never edited in place, only appended to (a new lineup event) or trimmed from the tail (Undo).

Every `GameEvent` is saved immediately when it is recorded, so a force-quit never loses more than a write already in flight.

## 9. Tech Stack and Architecture

Everything standard (accounts, iOS signing, XcodeGen, devices, the deploy recipe) is in the Project Build Guide; this section states only what is project-specific.

- Bundle ID: `com.levelup.soccermanager`.
- Repo: `nikolausj1/soccer-manager`, public (Justin's explicit call for this project, overriding the portfolio's private default; placeholder-only names and the `Local/` gitignore rule are mandatory from the first commit because of it).
- iOS 26.0 deployment floor, SDK 27 (locked for the current environment; Justin's phone itself runs iOS 27, the floor is lower only because this Mac has no iOS 27 simulator runtime installed and too little free disk to fetch one, see Section 12).
- `SwiftUI`, `SwiftData` (both locked), portrait only, no third-party packages.
- The engine lives in a local Swift package, `SoccerManagerCore`, pure Swift and Foundation only, so it is testable head-on with `swift test` independent of the app target or a simulator.
- Sim-verification target: simulator `SoccerManager-iPhone` (iPhone 16 Pro Max, iOS 26.5, UDID `9CB48E72-1FF3-4F73-B010-83AB57B6A0BD`), created at kickoff to match Justin's phone.

Architecture is a straight line: `SwiftUI` views read a `GameSnapshot` computed on demand from `SoccerManagerCore`, driven by `GameEventRecord`s persisted in `SwiftData`. The engine never imports `SwiftData` and never sees a player's name, only `UUID`s; the app layer is the only place names, persistence, and UI meet.

**Rejected alternatives:**

- A JSON file store in place of `SwiftData`. Off-pattern for this portfolio and closes the door on iCloud sync later, for no offsetting benefit in v1.
- A web app instead of native iOS. Cannot hold the screen awake through a half or survive the phone being locked, which the sideline moment requires.
- iCloud sync in v1. Deferred to v3: it touches every model in the app and only pays off if Justin's phone is lost or replaced, a cost not worth taking on before the on-device version has proven itself.

## 10. Build Phases

1. **Scaffold.** `project.yml` (deployment target 26.0, portrait only, `ITSAppUsesNonExemptEncryption: NO`, local package dependency on `SoccerManagerCore`), `.gitignore`, a Core package skeleton with one passing test, an app target with a placeholder root view, `xcodegen generate`, first commit, repo created and pushed.
   **Exit criterion:** `swift test` and a simulator build are both green, a sim-verified screenshot of the placeholder app lands in `_review/00-scaffold.png`, and `nikolausj1/soccer-manager` exists on GitHub with that first commit pushed.
2. **Engine.** Implement `GameEngine`, `GameEvent`, `GameSnapshot`, `PlayerStats`, `SeasonTotals` exactly to the data model in Section 8, with tests.
   **Exit criterion:** `swift test` is green with at least 30 assertions, covering at minimum: start and stop accrual, a swap while running, a swap while stopped changing nothing, a 10-minute gap with no events advancing exactly 600 seconds, keeper seconds counted inside field seconds, keeper stint counting across both an outfield and a bench keeper swap, Undo restoring the previous snapshot, ranking ties, and season sums equaling per-game sums.
3. **Screens.** All six screens from Section 6, `SwiftData` records from Section 8 wired to the engine, save after every event, idle timer held while Live is on screen, `-seedRoster` and `-autostartLiveGame` launch arguments.
   **Exit criterion:** a simulator build is green, and screenshots of every screen and named state (Roster, New game, Live in setup, running, one-selected, after-swap, and stopped-at-half, Summary, Season) land in `_review/` with placeholder names only.
4. **Verification.** Run all 7 success criteria from Section 3 against the running simulator app, force-quit with `simctl terminate` and relaunch mid-game, check every empty state, check Dynamic Type at the largest accessibility size, add a simple app icon.
   **Exit criterion:** each of the 7 success criteria is reported individually as pass or fail with evidence (a screenshot or a named test), and a final screenshot set is in `_review/`.
5. **Ship.** Review, commit any remaining work, tag `v1.0`, then Recipe A to Justin's phone: `xattr -cr Sources`, device build, `devicectl` install, launch, confirm running.
   **Exit criterion:** the app is installed and confirmed running on JustinN via `devicectl` output, the repo is tagged `v1.0`, and Justin has the final report with screenshots and the repo link.

## 11. Acceptance Criteria

**Success criteria:**

- [ ] Next off and next on are both visible for all 8 players with no scroll and no tap, in portrait.
- [ ] A swap takes two taps and completes in under 2 seconds measured from unlock.
- [ ] Undo is a single tap.
- [ ] Locking the phone for 10 minutes mid-half advances every running timer by exactly 10:00, within 1 second, once unlocked.
- [ ] Force-quitting and relaunching mid-half resumes the clock, the lineup, and every timer with no loss.
- [ ] Making a swap while the clock is stopped changes no player's field or bench seconds.
- [ ] Season totals equal the exact sum of the corresponding saved per-game totals.
- [ ] No real child's name appears anywhere in the repo or in any screenshot under `_review/`.

**Screen and state criteria:**

- [ ] Roster's empty state shows "Add your players." with no other content until a player is added.
- [ ] Roster supports add, rename, and archive (via swipe), with archived players excluded from attendance but retained in season history.
- [ ] Game tab's empty state shows only an empty-state message and a "New game" button when no game has ever been played.
- [ ] Game tab lists past games most recent first, each opening its Summary on tap.
- [ ] An in-progress game is always the Game tab's top row, pushing to Live when tapped or automatically the first time the tab appears after launch.
- [ ] New Game sheet defaults every active player to checked and blocks Start while zero players are checked.
- [ ] In `kickoff`, players can be tapped from bench to field and a keeper designated, with the clock not running and no time accruing.
- [ ] In `firstHalf` and `secondHalf`, field seconds accrue only to players currently on the field, tracking wall-clock time.
- [ ] Selecting one player highlights it as selected; selecting a second legal target completes the swap, keeper trade, or bench entry per Section 6's selection model; selecting the same row twice deselects it.
- [ ] After any swap, the Live screen's ranking (next off, next on) updates immediately to reflect the new state.
- [ ] Undo is hidden whenever there is no lineup event to undo, and otherwise labeled with what it will undo.
- [ ] Summary, shown after End Game and from the games list, lists field minutes, goal minutes, and goal stints per player for that one game.
- [ ] Season's empty state shows before any game has been finished.
- [ ] Season, once populated, sorts players by goal stints ascending then goal minutes ascending, so the top row is whoever is most due in goal.
- [ ] The screen stays awake (idle timer disabled) for the entire time Live is on screen with the game not `finished`, and idle-timer behavior returns to normal otherwise.
- [ ] The Live title shows the team name and the game's date, and the screen is pushed with a Back button top left and the tab bar hidden.
- [ ] The Live header matches its phase: `kickoff` and `halftime` show a label, a countdown at the full half length, and a green Start button ("Start 1st half" or "Start 2nd half"); `firstHalf` and `secondHalf` show the countdown running down from the half length, plus a subtitle.
- [ ] Past zero, the header shows "+m:ss" in red and keeps counting; the clock never auto-stops.
- [ ] "End Half" and "End Game" each open a confirming alert, and only the alert's confirm ends the phase or the game; Cancel leaves everything running and records nothing.
- [ ] Each outfield row shows a readiness bar: green under 60 percent, amber 60 to 100, red with a DUE badge at or above 100.
- [ ] Each bench row shows a green rest meter toward one shift length, plus NEXT ON and rested time.
- [ ] Roster's Settings section offers half length (5 to 45 minutes, by 5) and shift length (1 to 15 minutes) steppers; a change takes effect immediately.
- [ ] Swiping any row in the Game tab, finished or in progress, offers delete with a confirming alert required first.
- [ ] The Final score sheet offers Save and Skip; Skip leaves both scores unset.
- [ ] A saved final score appears in the Game tab's list row and in the Summary.
- [ ] An existing store from before this model change opens with no data loss, `currentBenchStintSeconds`, `ourScore`, and `theirScore` reading unset for games saved under the old model.

## 12. Risks and Open Questions

**Risks:**

- **Stray pocket touches while the screen is held awake.** A live game keeps the idle timer disabled, so an unintended touch against a pocket or leg could register as a tap. Mitigation: Undo is always one tap away and reverses the most recent lineup event; the two-second glance habit means Justin checks the screen each time he reaches for it, catching a stray tap quickly.
- **The iOS 27 simulator runtime is not installed on this Mac.** Xcode 27.0 carries the SDK but not a matching simulator runtime; only 18.3 and 26.5 are installed. Mitigation: build and simulate against a 26.0 deployment target for now (Section 9), revisit the floor once the runtime is available.
- **Disk space.** About 20 GB free at the time of writing is not enough headroom to comfortably download an additional simulator runtime. Mitigation: keep using the installed 26.5 runtime for sim-verification, do not attempt a runtime download until more space is freed.
- **XcodeGen can drop a resource silently.** Adding a file to the project without regenerating, or a misconfigured resource path, can produce a build that succeeds but ships without an asset. Mitigation: rerun `xcodegen generate` after adding any resource and confirm it by listing the contents of the built `.app`, not just by a green build.
- **Readiness thresholds (60 percent amber) are a guess.** Mitigation: tune after two games.
- **No pause means an injury stoppage inflates that shift's minutes.** Mitigation: acceptable for rec play; a pause behind the half display is a one-line add if asked.

**Open questions (non-blocking, ask Justin, do not decide):**

- Show the gap from even ("+3", "-4") beside or instead of raw game totals. Decide at screen design, in `_review/` mockups. Less pressing now that readiness is shown per row, but still open.
- Fewer than 5 kids present: the app allows any number on the field. Placeholder rule: no minimum enforced.
- Jersey numbers on the roster: not in v1 unless Justin asks.
