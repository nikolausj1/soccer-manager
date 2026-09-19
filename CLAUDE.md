---
title: "CLAUDE - Soccer Manager"
created: 2026-09-19
modified: 2026-09-19
version: 1.0
author: Claude Opus 5 (claude-opus-5)
tags:
---

# Soccer Manager

An iOS app for Justin's phone, used on the sideline while he coaches, so the kids on his team get roughly equal field time. A bench and a field he moves players between; live and cumulative minutes per player; who is due to come off; season totals including time in goal. Scaffolded by Oracle on 2026-09-19. Stage: Idea.

**Nothing about this product is decided yet** beyond the name, the platform and the outcome. Do not infer a design from this file. The idea dump is one paragraph of Justin's own words and a four-item wish list, and that is the entire input.

## Your first job

1. Read `_inbox/idea-dump.md` in full. It is a raw dump, not a spec.
2. Read `STATUS.md`, in particular the genesis notes: what Justin decided, what he named without deciding, and what he deliberately left to you.
3. Run the interrogation with Justin per the protocol in `~/Library/CloudStorage/Dropbox/_Projects/_Templates/PRD Template.md`: **one question at a time**, conversationally, challenging rather than transcribing. Push on the real problem, on what winning looks like in testable terms, on the smallest v1 that proves it, and on what is explicitly out. Reflect back a one-paragraph summary and get a "yes, that's it" before drafting anything.
4. Draft `PRD.md` when you could answer the template's quality checklist. Mark anything still soft as an open question rather than inventing an answer.
5. Only then the new project kickoff checklist in the Project Build Guide: confirm the platform, create the repo, `.gitignore`, scaffold, and prove a build runs before any feature code.

Questions worth carrying into the interrogation, as questions and not as assumptions: what the sideline moment actually looks like while a game is running; what "even" means to Justin and whether goalkeeper minutes count toward it; what happens when the phone locks, the app is backgrounded, or he forgets to tap; whether a season exists in the app or only a game; and who, if anyone, other than Justin ever holds the phone.

**Ask Justin in chat, one decision at a time, as numbered options with the recommended one marked.** He has asked for that format and dislikes the AskUserQuestion UI.

## The two shared documents

Both live in Dropbox and are **referenced, never copied**:

- `~/Library/CloudStorage/Dropbox/_Projects/_Templates/Project Build Guide.md` - accounts, iOS signing (team `6A4J2GTB6F`, bundle IDs `com.levelup.<shortname>`), XcodeGen, devices, Recipe A for deploying to Justin's iPhone, and the standing rule "verify, screenshot, show Justin, wait, then deploy". Read its Changelog at session start.
- `~/Library/CloudStorage/Dropbox/_Projects/_Templates/PRD Template.md` - the interrogation protocol and the PRD structure.

**Never edit either one.** Justin's standing rule since 2026-08-12. Your channel is a `## Lessons` entry in this project's `STATUS.md`; Oracle vets those and folds the good ones in. If a guide error is actively blocking you, say so in `## Health` so it surfaces at the top of the next rollup.

## Things already settled by the portfolio

- This project lives in `~/_Developer`, outside Dropbox, on purpose. Keep it there. Build to `/tmp`; never point `-derivedDataPath` inside the repo or a cloud-synced folder.
- The bundle ID (`com.levelup.<shortname>`) and the private repo name are yours to pick at kickoff, with Justin.
- `_inbox/` is what Justin drops in for you. `_review/` is what you put in front of him: mockups, screenshots, options to choose from. Both are gitignored and both travel with the project.
- Kids' names are real children's names. Keep them out of anything committed, shipped, or screenshotted for review; a single config or fixture file, gitignored, is the pattern used elsewhere in this portfolio.

## Oracle Reporting Contract

This project is tracked by Oracle, the portfolio agent at the `_Projects` root, which rolls every project's status into `_Oracle/PORTFOLIO.md` and a dashboard. Parent standards and the Oracle Status Format are defined in `~/Library/CloudStorage/Dropbox/_Projects/CLAUDE.md` (inherited; read it). Your obligations:

1. **Keep `STATUS.md` current.** Refresh it at the end of any session with meaningful progress, decisions, or new blockers.
2. **Follow the Oracle Status Format exactly**: Project, Stage, Health, Waiting on Me, Next Up, Biggest Risk, in that order. Anything project-specific goes below a `---` divider. Bump `version` and update `modified` on every edit.
3. **Keep the Ideas Shelf stocked** with 2 to 5 self-contained items sized S/M/L that Justin could pick up for fun.
4. **Never delete `STATUS.md`.** If parking the project, set Stage to Paused and say why.
5. **Oracle trusts this file completely.** It never inspects code or git. An inaccurate status gives Justin a wrong portfolio picture.
6. Edits marked "updated via Oracle at Justin's direction" are authoritative. Reconcile them at session start; do not revert them.
7. **Share what you learn, and only through `STATUS.md`.** Reusable environment-level findings go in an optional `## Lessons` section at the bottom, below the divider. Never edit anything in `_Oracle/` or `_Templates/`.

## Waiting on Me items

Every item under `## Waiting on Me` needs a bolded concrete action, an effort estimate in parentheses, and an indented `- unblocks:` line.

## File standards

Markdown with YAML front matter (title, created, modified, version, author, tags blank) on every `.md` file. No em dashes anywhere. Code, commands, and paths in code blocks or inline code. Semantic versions; `modified` updated on every edit, `created` never changed.
