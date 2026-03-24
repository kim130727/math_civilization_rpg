# Migration Plan

## Audit Summary

### Keep and adapt

- `scripts/autoload/DialogueManager.gd`
  - Lightweight signal bus that still works for small worldbuilding beats.
- `scenes/ui/DialogueBox.tscn`
  - Reused as the modal text surface for encounter intros and run completion notes.
- Progression-as-data idea
  - The old `PuzzleProgress` save boundary was useful, but its responsibility is now rebuilt as `MetaProgression`.

### Deprecate into `legacy/`

- `legacy/main`
  - Old map/puzzle screen switching entry point.
- `legacy/scenes_world`, `legacy/scenes_player`, `legacy/scenes_interactables`
  - Free-walk exploration assumptions no longer define the core loop.
- `legacy/scenes_puzzle`, `legacy/scripts_puzzle`, `legacy/Match3BoardController.gd`
  - Match-3 board logic is intentionally isolated instead of being stretched into encounter combat.
- `legacy/data_levels`
  - Old board-specific level resources are preserved for reference only.
- `legacy/GameState.gd`, `legacy/InventoryManager.gd`, `legacy/AbstractionManager.gd`, `legacy/PuzzleProgress.gd`
  - Responsibilities either vanished with exploration or were renamed and narrowed.

### Replace

- Main flow
  - `main/Main.tscn` now hosts the deckbuilder loop: run map -> encounter -> reward.
- Progression
  - `scripts/autoload/MetaProgression.gd` replaces puzzle-star progression with concept/card/relic discovery.
- Content data
  - Card, encounter, relic, archetype, and map data are now explicit `Resource` types.

## New Folder Structure

```text
main/
scenes/
  encounter/
  reward/
  run/
  ui/
scripts/
  app/
  autoload/
  cards/
  deck/
  encounter/
  relics/
  rewards/
  run/
data/
  archetypes/
  cards/
  encounters/
  relics/
  run/
docs/
legacy/
```

## Autoload Migration

- Keep: `DialogueManager`
- Add: `MetaProgression`
- Remove: `GameState`, `InventoryManager`, `AbstractionManager`, `PuzzleProgress`

## Scene Migration

- Old `legacy/main/Main.tscn`
  - Archived.
- New `main/Main.tscn`
  - Hosts the actual run-state based deckbuilder loop.
- New `scenes/run/RunMapView.tscn`
  - Node map and deck summary.
- New `scenes/encounter/EncounterView.tscn`
  - Slot-based mathematical encounter surface.
- New `scenes/reward/RewardView.tscn`
  - Draft and relic rewards.

## Vertical Slice Scope

- 1 archetype: `Field Cartographer`
- 15 cards across counting, addition, multiplication
- 5 encounters
- 1 mini run map
- 2 relics

## Follow-up TODOs

- Add richer targeting and multi-step card effects.
- Add permanent unlock pacing outside the single-run slice.
- Replace placeholder control-based map rendering with a bespoke node-map visual.
- Add animation, sound, and encounter variants once the rule surface stabilizes.
