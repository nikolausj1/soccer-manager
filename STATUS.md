---
title: "STATUS - Soccer Manager"
created: 2026-09-19
modified: 2026-09-19
version: 1.2
author: Claude Fable 5.1 (claude-fable-5-1)
tags:
---

# Soccer Manager - Status

## Project

An iOS app Justin runs on his phone on the sideline so the kids he coaches get roughly equal field time, including time in goal, with a bench and a field he taps players between.

## Stage

MVP

## Health

🟢 On-track. v1.0 built, verified on the simulator (7 of 7 acceptance criteria, 23 engine tests), tagged, and installed on Justin's iPhone on 2026-09-19. Not yet used in a real game.

## Waiting on Me

- [ ] **Enter the real roster in the app on the phone, then use it in the next game and report what broke** (5 min setup, one game)
      - unblocks: v1.1 decisions (backdate nudge, half-length setting, gap-from-even display)

## Next Up

1. Justin runs one real game on v1.0 and reports.
2. Triage the report into v1.1 (Ideas Shelf has the candidates).
3. Free disk space, install the iOS 27 simulator runtime, raise the deployment floor to 27.

## Biggest Risk

If reading who's next or completing a swap ever takes longer than a two-second glance, Justin stops using the app mid-game and the minutes go untracked, which defeats the whole point.

---

## Decisions

Locked decisions from the interrogation; see `PRD.md` for full detail on each.

- **Keeper minutes count as field minutes, tracked separately too.** Goalie is the coveted spot at U8, not a punishment, so the rotation has to be visibly fair.
- **"Poised to come off" ranks by cumulative game total**, not current stint. Matches the actual problem: who has played the most, not who has been out the shortest time.
- **Tap-tap swap, one Undo.** The best one-handed, outdoor gesture available; drag and drop and select-then-commit were both rejected.
- **Clock started and stopped per half by Justin**, minutes derived from wall-clock timestamps. Survives locking and backgrounding with no loss.
- **Undo only in v1, no edit history.** Late taps cost the delay, acceptable against "roughly equal."
- **Silent in the pocket, no alerts, screen stays awake during a live game.** Justin decides when to look, the app never buzzes him.
- **One team, one season, on-device only, no accounts or sync.** Nothing to sync to yet; iCloud is a v3 candidate, not a v1 cost.
- **iPhone only, SwiftUI, SwiftData, portrait, no third-party packages.** Bundle ID `com.levelup.soccermanager`, repo `nikolausj1/soccer-manager`, public (Justin's call).
- **Team identity is Algeria, palette is the flag** (green `#006233`, red `#D21034`, white background). Set by Justin 2026-09-19; see PRD.md Section 7. The team name is not personal information, so it lives in a plain source constant, unlike the kids' names.

## Deferred

- v1.1: backdate-last-swap nudge, only if wanted after 2 or 3 games.
- v1.2: soft "half has passed 20:00" reminder, never an auto-stop.
- v2: lock-screen Live Activity (half, elapsed, next off, next on).
- v2: "start new season" archive.
- v3: iCloud sync.

## Ideas Shelf

- **Backdate-last-swap chips** (S): quick "actually 2 minutes ago" correction for a late tap, instead of full history editing.
- **Gap-from-even display** (S): show "+3" / "-4" beside or instead of raw game totals on the Live screen.
- **Lock-screen Live Activity** (M): half, elapsed, next off, next on, visible without unlocking.
- **Start-new-season archive** (M): close out the current season and begin a fresh one without losing history.

## Lessons

- `xcrun devicectl device install app` fails with CoreDeviceError 10003 "device was still locked" when the iPhone is locked. A retry loop every 20 seconds until the unlock works well and needs no human timing; tell Justin to unlock the phone before Recipe A.
- XcodeGen does not set `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` or `ASSETCATALOG_COMPILER_APPICON_NAME`. Without both in `project.yml` `settings.base`, the AccentColor asset is silently ignored (everything renders system blue) and the AppIcon set is not used. Add both to every iOS `project.yml`.
- The iOS Simulator MCP tool's `inspect` action was unavailable in this session while `tap`, `button` and `screenshot` worked; coordinates were calibrated from screenshot scale instead. Launch-argument seeding for every screen state (`-resetData`, `-seedRoster`, `-autostart...`) made the screenshot pass repeatable and is worth building into every app from the first screen.

- Xcode 27.0 on this Mac carries the iOS 27 SDK but no iOS 27 simulator runtime, only 26.5 and 18.3 are installed, and about 20 GB free disk made downloading one a bad idea. The deployment target is 26.0 until disk space frees up.
- The Build Guide's repo-create example uses `--public` while a project's own `CLAUDE.md` may ask for private, so the flag is a per-project decision to confirm, not something to copy from the example. Justin chose public here.

## Genesis

Justin asked for this project in a Cowork session on 2026-09-19, scaffolded by Oracle with the name, `~/_Developer/Soccer Manager` as location, iOS as platform, and even field time as the purpose, everything else left to the interrogation. Roster row added to `_Oracle/PROJECTS.md` at P3, type `ios, tool`.
