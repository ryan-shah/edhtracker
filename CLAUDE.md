# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Lint / static analysis
flutter test             # Run widget tests
flutter build web --release --base-href /edhtracker/   # Production web build (used by CI)
```

CI/CD auto-deploys to GitHub Pages on push to `main` via `.github/workflows/deploy_github_page.yml`.

## Architecture

Flutter app (no third-party state management — plain `StatefulWidget` throughout). Targets Android, iOS, Web, and Windows.

**Screen flow:**
```
GameSetupPage → LifeTrackerPage → GameSummaryPage / PostGameReviewPage
```

**GameSetupPage** (`game_setup_page.dart`) — collects 4 players' names, commanders (with partner support), and starting life total. Commander search hits the Scryfall API via `ScryfallService`; art is cached in `SharedPreferences` with a 24-hour TTL.

**LifeTrackerPage** (`life_tracker_page.dart`) — the main gameplay screen. Locked to landscape. Renders four `PlayerCard` widgets and manages global state: turn counter, turn timer, undo stack, and game logging. Each turn end appends a `TurnLogEntry` to `GameLogger`.

**PlayerCard** (`player_card.dart`) — self-contained widget for one player. Spawns overlay sheets (`CounterOverlay`) for commander damage, counters (Energy/Experience/Poison/Rad), and action tracking (Life Paid, Cards Milled, Extra Turns, Cards Drawn).

**GameLogger** (`game_logger.dart`) — serializes full game state to JSON after every turn. Powers both the undo feature (in-memory stack) and post-game file export.

**GameStatsUtility** (`game_stats_utility.dart`) — pure utility: consumes `GameLogger` data to compute post-game stats (damage dealt per player, longest turn, action totals).

**ScryfallService** (`scryfall_service.dart`) — all Scryfall API calls (card search, art URL lookup) plus `SharedPreferences`-backed image caching.

## Key Conventions

- All UI constants (colors, spacing, font sizes, dimensions) live in `constants.dart` — add new ones there rather than inline.
- Commander damage matrix and counter state are owned by `LifeTrackerPage` and passed down; `PlayerCard` fires callbacks upward.
- The app enforces landscape orientation during gameplay and portrait for setup/review screens via `SystemChrome` calls.
- Overlays use a responsive 1–2 column grid defined in `CounterOverlay`.


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
