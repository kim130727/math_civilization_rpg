# Math Civilization Roguelike

Godot 4 deckbuilding roguelike prototype about mathematical abstraction as strategy.

This repository no longer treats match-3 or free-walking exploration as the core gameplay. The primary game loop is now:

1. Start a run with a thinker archetype and a small starter deck
2. Move through a node map of encounters
3. Enter a mathematical structure encounter
4. Play cards to build, combine, preserve, and scale values across slots
5. Clear the objective and draft a new card or relic
6. Push into harder abstractions

## Design Direction

- Counting is precision and exact placement
- Addition is consolidation and efficient accumulation
- Multiplication is repetition, equal groups, and scaling
- Encounters are objective-driven structures, not HP races
- Cards express operations and transformations instead of flavored attack numbers

## Current Vertical Slice

- 1 archetype: `Field Cartographer`
- 15 data-driven cards
- 5 encounter templates
- 2 relics
- 1 mini run map
- `MetaProgression` save data for concept and discovery tracking

## Architecture

### Core runtime

- `main/Main.tscn`
- `scripts/app/MainFlowController.gd`
- `scripts/run/RunState.gd`
- `scripts/deck/DeckManager.gd`
- `scripts/encounter/EncounterEngine.gd`
- `scripts/rewards/RewardGenerator.gd`

### Data resources

- `scripts/cards/CardDefinition.gd`
- `scripts/encounter/EncounterDefinition.gd`
- `scripts/relics/RelicDefinition.gd`
- `scripts/run/ArchetypeDefinition.gd`
- `scripts/run/RunNodeDefinition.gd`
- `scripts/run/RunMapDefinition.gd`

### Scenes

- `scenes/run/RunMapView.tscn`
- `scenes/encounter/EncounterView.tscn`
- `scenes/reward/RewardView.tscn`
- `scenes/ui/DialogueBox.tscn`

## Legacy

Earlier exploration-RPG and match-3 systems have been isolated under `legacy/` so the deckbuilder architecture remains the primary truth of the project.

## Notes For Iteration

- The encounter UI is intentionally plain while the architecture settles.
- TODO hooks are left in the engine for richer entropy, relic timings, and more complex card rules.
- Future content can extend fractions, division, arrays, relations, and higher abstractions by adding new resources and effect handlers rather than rewriting the core loop.
