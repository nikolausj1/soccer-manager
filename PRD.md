---
title: "Soccer Manager - Product Requirements Document"
created: 2026-09-19
modified: 2026-09-19
version: 1.0
author: Claude Fable 5.1 (claude-fable-5-1)
tags:
---

# Soccer Manager - Product Requirements Document

| | |
|---|---|
| **Product** | Soccer Manager, a sideline substitution tracker that keeps playing time even |
| **Platform** | iOS |
| **Status** | v1.0 PRD - agreed 2026-09-19 |
| **Companion docs** | `Project Build Guide.md` (accounts, stack, deployment - follow it, do not restate it) |

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
- Start and stop the clock per half, with an optional Pause.
- End game, with a per-kid summary.
- Season totals screen.
- Screen stays awake while a game is live.
- Survives force-quit and relaunch mid-game with no data loss.

**Out of scope (non-goals):**

- Alerts or buzzes when someone is due off. Justin decides when to look, the app never interrupts him. A "someone is due" buzz was rejected because it second-guesses the coach's own attention.
- Drag and drop for substitutions. Rejected as the worst one-handed, outdoor gesture available, in favor of tap-tap.
- A prescribed or auto-generated rotation schedule. Rejected as brittle, and because it fights the reality that Justin moves kids for reasons the app cannot see.
- Multi-team or multi-season UI. One team, one running season is the whole scope; anything more is complexity nobody uses.
- Sync or accounts. Everything lives on Justin's phone only; there is nothing to sign into and nothing to sync to in v1.
- Editing a finished game's history, or editing any past event beyond Undo. Late taps cost the delay; that cost is accepted against "roughly equal."
- Anything parent- or league-facing. Proof of playing time for parents or a league is explicitly not a goal, even though a per-game record exists as a byproduct.
- Positions, formations, score, statistics beyond minutes and keeper stints. None of these serve the even-minutes problem.
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
3. **Even is a ranking, not an alert.** The app never tells Justin someone is due, it only ever shows the order. He decides when to look and when to act; the app supplies memory, not judgment.

## 6. Functional Requirements

Three tabs: **Game**, **Season**, **Roster**. Built in `SwiftUI` (locked). Every screen reads local `SwiftData` synchronously, so unless a screen says otherwise below, it has no loading state; and unless noted, it has no error state either, since a local on-device write either succeeds or the app has a bug, not something v1 designs a recovery flow for.

### Roster

Editable list of active players. Add a player by name. Rename in place. Archive via swipe; archived players are hidden from attendance but stay in season history.

- Empty: no players yet. Shows "Add your players." and the add-player control. No game can be created until at least one player exists.

### Game tab

If a game is currently in progress (state `setup`, `running` or `stopped`, anything not `finished`), this tab is the Live screen. Otherwise it is a list of past games, most recent first, each row a date and a one-line summary, with a "New game" button.

- Empty: no games played yet. Shows an empty-state message and the "New game" button, nothing else.

### New game sheet

Attendance checklist over the active roster, every player checked by default. "Start" creates the game with every checked player on the bench, nobody on the field yet, and opens Live in the `setup` state.

- Empty: if the roster itself is empty, the sheet cannot be reached; Roster's empty state governs instead.
- Error: zero players checked. "Start" is disabled until at least one player is checked; a game with an empty attendance list has nothing for the engine to rank.

### Live

Header: half indicator (1st or 2nd, changeable only while the clock is stopped), elapsed time in the half, one Start/Stop control (Pause uses the same control). Field section: keeper slot, then outfield ranked most-played first, top row flagged **NEXT OFF**. Bench section: ranked least-played first, top row flagged **NEXT ON**. Every row shows name, current stint, game total, goal share if nonzero, and a `GK` badge for the keeper.

Selection model (locked, tap-tap swap): tap a row to select it, tap a second row to act, tap the same row again to deselect.

- Field player + bench player selected: they swap.
- Keeper + field player selected: roles trade.
- Keeper + bench player selected: the bench player enters in goal, the keeper goes to the bench.
- Bench player + an empty field slot selected: the bench player enters (covers fewer than 5 on the field).
- Field player selected + "To bench" header: that player leaves the field without a replacement.

Undo is labeled with what it will undo and is hidden entirely when there is nothing to undo. "End game" is shown only while the clock is stopped, and asks for confirmation before finishing. The screen is held awake (idle timer disabled) for as long as Live is on screen and the game is not `finished`.

- Empty (`setup`): no game yet in progress; the Game tab's empty state applies until a game is created.
- Error: an action that is not currently legal (for example, tapping End Game while the clock runs) is simply not offered rather than shown and rejected. See the edge case table below for the specific cases this covers.

### Summary

Shown immediately after End Game, and by tapping any past game from the Game tab's list. Per player for that game: field minutes, goal minutes, goal stints.

- Empty: not reachable. A game cannot be started with zero attendance (see New game sheet's error state), so a `Summary` always has at least one player to show.

### Season

Per active player: games played, field minutes, goal minutes, goal stints, sorted by goal stints ascending then goal minutes ascending, so the top row is whoever is most due for a turn in goal.

- Empty: no finished game yet. Shows an empty-state message; the tab has nothing to total.

### Game state machine

Four states: `setup`, `running`, `stopped`, `finished`.

- **`setup`**: the game exists (created from the New Game sheet) but the clock has never started, no `clockStart` event has been recorded yet. Justin builds the initial lineup by tapping bench players onto field slots and designating a keeper; each tap-tap pair records a `lineup` snapshot event but nothing accrues time, since the clock has not run.
- **`running`**: the clock is running (`clockRunning == true`). Time accrues to whichever players are on the field. Lineup changes are allowed and take effect immediately; they record a `lineup` event but never a clock event.
- **`stopped`**: at least one `clockStart` has occurred, but the clock is not currently running. Covers both a mid-half pause and the gap between halves. Lineup changes are allowed and recorded, but accrue no time (success criterion 5). The half control is changeable only here. End Game is offered only here.
- **`finished`**: End Game was tapped and confirmed. Terminal state; the game moves into season totals and the Summary is shown. Nothing in a `finished` game can be edited in v1; Undo only ever acts on a game that is not yet finished.

Transitions: `setup -> running` on the first Start. `running -> stopped` on Stop. `stopped -> running` on Start (resumes the current half, or begins the half just selected by the half control). `stopped -> finished` on End Game plus confirmation. Lineup edits happen inside `setup`, `running`, or `stopped` without changing the state itself.

### Edge cases

| Case | Behavior |
|---|---|
| Swap while stopped | A lineup snapshot event is recorded and the on-field/bench assignment changes immediately, but nobody's field seconds or bench seconds change, because no time accrues outside `running` (success criterion 5). |
| Keeper swap with bench player | Same tap-tap gesture as any swap: tap the keeper, tap a bench player. One `lineup` event records the bench player as the new keeper and the old keeper moves to the bench. A new keeper stint begins for the player entering goal. |
| Undo after clock stop | Undo always removes only the single most recent `lineup` event and restores the previous snapshot, whether the clock is currently running or stopped. It never touches `clockStart` or `clockStop` events. |
| Fewer than 5 present | No minimum is enforced. The field can hold any number of players, including an empty slot; an empty field slot is filled by selecting a bench player next (see Live's selection model). |
| Force-quit mid-half | On relaunch, the engine rebuilds the current `GameSnapshot` by replaying the full stored event log against the current time. If the log's last clock event was `clockStart`, the clock resumes running and every player's seconds reflect the full wall-clock gap; nothing is lost (success criterion 4). |
| App backgrounded 10 minutes | Time is derived from event timestamps and wall-clock `now` at snapshot time, never from an in-process timer. Backgrounding changes nothing about what is stored; on foreground, every running player's seconds include the full 10 minutes (success criterion 3). |
| End game tapped while running | Not reachable through the UI: the End Game control is shown only while the clock is `stopped`. Stop must be tapped first. |
| Second half started without stopping first | Not reachable through the UI: the half control can only be changed while `stopped`, and starting the clock always begins accrual under whatever half is currently selected at that moment. |

## 7. Visual and Design Spec

Locked, from the interrogation, with the team-identity decision Justin made on 2026-09-19:

- The team is **Algeria**; the palette is the flag. Background is white, light mode first, no dark mode requirement for v1.
- Accent color and the **NEXT ON** highlight (top-ranked bench row): Algeria green `#006233`.
- The **NEXT OFF** highlight (top-ranked outfield row): flag red `#D21034`.
- The `GK` badge, wherever the keeper appears, is green (`#006233`).
- System fonts throughout, no custom typography.
- Player names render at least at title text size, the single most important legibility requirement given outdoor glare and a two-second glance.
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

Per player, per game: `fieldSeconds`, `keeperSeconds`, `keeperStints`, `currentStintSeconds?`, `currentKeeperStintSeconds?`, `benchSeconds`.

**Invariant (locked): time accrues only while the clock runs.** Seconds move only between a `clockStart` and the next `clockStop`, or up to `now` if the clock is currently running. Lineup changes recorded while the clock is stopped change nobody's seconds.

**Invariant: field seconds include keeper seconds.** Keeper time is a subset of field time, not additional to it; a keeper is never double-counted against a total-minutes figure.

Keeper stints increment by one on each lineup event where the keeper becomes a player who was not the keeper in the immediately previous snapshot; the first lineup event of the game that has a keeper at all counts as a stint too. Current stint resets to zero whenever a player enters the field, and accumulates only while the clock is running.

Ranking: outfield sorted by `fieldSeconds` descending, tie broken by `currentStintSeconds` descending, then by attendance order. Bench sorted by `fieldSeconds` ascending, tie broken by `benchSeconds` descending, then attendance order. The keeper is never included in `rankedOutfield`. `nextOff` is the first ranked outfield player, `nextOn` is the first ranked bench player, both `nil` when their list is empty.

### SeasonStats

`SeasonTotals.compute(games:) -> [UUID: SeasonStats]`, over `(attendance: [UUID], events: [GameEvent])` pairs, finished games only. Per player: `gamesPlayed`, `fieldSeconds`, `keeperSeconds`, `keeperStints`.

**Invariant: season totals equal the exact sum of the corresponding per-game totals** for every finished game (success criterion 6). There is no independent season ledger to drift out of sync.

### SwiftData persistence (locked)

Three record types persist this model, one to one, so the engine's pure functions can be re-run against stored data at any time with no migration:

- `PlayerRecord`: roster identity, name, active or archived. Source of truth for the `attendance` lists and for names, which never enter the engine.
- `GameRecord`: one per game, holding its date, its attendance (the `[UUID]` list the engine needs), and whether it is `finished`. Summary and Season both read finished `GameRecord`s.
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
- [ ] Game tab shows the Live screen directly, instead of the list, whenever a game exists that is not `finished` (including one still in `setup`).
- [ ] New Game sheet defaults every active player to checked and blocks Start while zero players are checked.
- [ ] Live's `setup` state lets players be tapped from bench to field and a keeper designated, with the clock stopped and no time accruing.
- [ ] Live's `running` state accrues field seconds only to players currently on the field, tracking wall-clock time.
- [ ] Live's `stopped` state allows the half control to change and offers End Game; neither is available while `running`.
- [ ] Selecting one player highlights it as selected; selecting a second legal target completes the swap, keeper trade, or bench entry per Section 6's selection model; selecting the same row twice deselects it.
- [ ] After any swap, the Live screen's ranking (next off, next on) updates immediately to reflect the new state.
- [ ] Undo is hidden whenever there is no lineup event to undo, and otherwise labeled with what it will undo.
- [ ] Summary, shown after End Game and from the games list, lists field minutes, goal minutes, and goal stints per player for that one game.
- [ ] Season's empty state shows before any game has been finished.
- [ ] Season, once populated, sorts players by goal stints ascending then goal minutes ascending, so the top row is whoever is most due in goal.
- [ ] The screen stays awake (idle timer disabled) for the entire time Live is on screen with the game not `finished`, and idle-timer behavior returns to normal otherwise.

## 12. Risks and Open Questions

**Risks:**

- **Stray pocket touches while the screen is held awake.** A live game keeps the idle timer disabled, so an unintended touch against a pocket or leg could register as a tap. Mitigation: Undo is always one tap away and reverses the most recent lineup event; the two-second glance habit means Justin checks the screen each time he reaches for it, catching a stray tap quickly.
- **The iOS 27 simulator runtime is not installed on this Mac.** Xcode 27.0 carries the SDK but not a matching simulator runtime; only 18.3 and 26.5 are installed. Mitigation: build and simulate against a 26.0 deployment target for now (Section 9), revisit the floor once the runtime is available.
- **Disk space.** About 20 GB free at the time of writing is not enough headroom to comfortably download an additional simulator runtime. Mitigation: keep using the installed 26.5 runtime for sim-verification, do not attempt a runtime download until more space is freed.
- **XcodeGen can drop a resource silently.** Adding a file to the project without regenerating, or a misconfigured resource path, can produce a build that succeeds but ships without an asset. Mitigation: rerun `xcodegen generate` after adding any resource and confirm it by listing the contents of the built `.app`, not just by a green build.

**Open questions (non-blocking, ask Justin, do not decide):**

- Show the gap from even ("+3", "-4") beside or instead of raw game totals. Decide at screen design, in `_review/` mockups.
- Half length: fixed at 20 minutes for v1, or a setting. Placeholder rule: fixed at 20, no auto-stop, so it only affects the display.
- Fewer than 5 kids present: the app allows any number on the field. Placeholder rule: no minimum enforced.
- Jersey numbers on the roster: not in v1 unless Justin asks.
