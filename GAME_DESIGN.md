# Game Design Pivot: Math Civilization Puzzle

## Vision

Turn the project into a mobile-style puzzle game where players rebuild a broken civilization by learning mathematical abstractions in play.

The emotional promise is:

"I am restoring order to the world, and math is the language that makes restoration possible."

This should feel closer to a restoration puzzle game than an RPG. The player is not wandering around looking for combat. They are solving compact puzzle levels, earning progress, and watching the world become more structured and more alive.

## Player Experience

The player should feel these beats in order:

1. This puzzle is simple and readable.
2. I solved it by noticing a pattern.
3. The world changed because of what I learned.
4. I want to see what the next math idea does.

The game should teach by repetition and discovery, not by lecture.

## Product Pillars

### 1. Restoration

Every clear should visibly repair the world.

- numbers separate a blurry world into countable objects
- addition combines scattered parts into useful structures
- multiplication creates repeated patterns, fields, tiles, and groups
- fractions split resources fairly and precisely
- division organizes large amounts into equal sets

### 2. Gentle Math Learning

Every chapter introduces one idea at a time.

- no long text explanations
- concepts first appear as intuitive mechanics
- names are introduced only after the player already used the idea

### 3. Short Mobile Sessions

Stages should be completable in roughly 30 to 90 seconds.

- one clear objective
- one main mechanic
- quick failure recovery
- visible rewards after every clear

### 4. Layered Progression

The player always has something to chase.

- stage clear
- star rewards
- chapter unlocks
- world restoration
- new mechanic reveals

## Core Game Loop

1. Enter a stage from the world map
2. Solve a short puzzle
3. Earn 1 to 3 stars based on performance
4. Spend stars to restore a scene in the civilization
5. Unlock story snippets, visual changes, and new puzzle mechanics
6. Progress to the next abstraction chapter

## Structure Similar to Restoration Puzzle Games

Use a hub-and-stage structure:

- world map with districts
- each district represents one math abstraction
- each restoration task costs stars
- completing restoration reveals new NPCs, objects, and mechanics

Example district flow:

- Chapter 1: Village of Counting
- Chapter 2: Bridge of Addition
- Chapter 3: Farm of Multiplication
- Chapter 4: Harbor of Fractions
- Chapter 5: Workshop of Division
- Chapter 6: City of Ratios
- Chapter 7: Clocktower of Functions
- Chapter 8: Observatory of Coordinates

## Teaching Sequence

### Chapter 1. Counting

Learning goal:
The player learns that objects can be identified, counted, and matched to quantities.

Puzzle ideas:

- tap all groups with exactly 3 objects
- connect numeral 4 to a group of 4 items
- clear tiles by selecting the larger count
- count hidden objects revealed one by one

Restoration fantasy:

- blurry shapes become separate objects
- shelves, stones, flowers, and lanterns become countable

### Chapter 2. Addition

Learning goal:
Two groups can be combined into one total.

Puzzle ideas:

- merge two groups to hit a target number
- choose the correct pair that sums to the goal
- route falling number tiles into buckets to make totals
- open gates by building the required sum

Restoration fantasy:

- broken bridge pieces combine into a bridge
- scattered supplies become complete bundles

### Chapter 3. Multiplication

Learning goal:
Repeated equal groups create large totals efficiently.

Puzzle ideas:

- create rows and columns to match a target
- choose between repeated addition and multiplication patterns
- fill a field with equal plots
- build arrays such as 3 x 4 by arranging tiles

Restoration fantasy:

- farmland expands in grids
- fences and pathways repeat in patterns

### Chapter 4. Fractions

Learning goal:
A whole can be divided into equal parts.

Puzzle ideas:

- cut shapes into halves, thirds, and fourths
- match fraction pieces to containers
- combine pieces to complete one whole
- identify which split is fair

Restoration fantasy:

- pies, water tanks, gardens, and stained glass are repaired through equal partitioning

### Chapter 5. Division

Learning goal:
A quantity can be split into equal groups or measured by group size.

Puzzle ideas:

- distribute 12 apples equally among 3 baskets
- decide how many groups of 4 fit in 16
- rebalance delivery carts with equal loads
- repair machines that require equal output channels

Restoration fantasy:

- workshops and logistics systems start working
- roads and carts become organized instead of chaotic

## Puzzle Format Recommendations

The project should not depend on a single puzzle type forever. It should use a family of related puzzle systems.

Recommended structure:

- base board puzzle for most levels
- special mechanic stages for concept mastery
- restoration scenes between puzzle clusters

### Option A. Merge Number Puzzle

Good for counting, addition, multiplication.

- number tokens appear on a compact grid
- dragging combines tokens or groups
- goals ask for totals, pairings, or arrays

### Option B. Match-and-Make Puzzle

Good for mobile retention and breadth.

- collect colored pieces and number pieces
- completing matches charges math actions
- actions solve chapter-specific math goals

### Option C. Partition Puzzle

Good for fractions and division.

- slice, distribute, or group objects
- fairness and equality become visible mechanics

Best approach:

Use one main board framework and allow chapter modifiers. This keeps the game readable while still letting the math evolve.

## Recommended Primary Mechanic

For this project, the best fit is:

"A compact grid puzzle where tiles represent quantities, groups, or parts, and chapter rules change what counts as a correct move."

Why this works:

- easy to read on mobile
- supports multiple math concepts
- can scale in complexity without changing the whole app
- keeps the abstraction theme strong

## Meta Progression

Use a star-based restoration loop.

- each level awards up to 3 stars
- stars repair buildings, farms, bridges, and monuments
- each restoration unlocks dialogue and art changes
- some restorations unlock new puzzle mechanics

This creates natural motivation without needing enemies.

## Narrative Style

Story should be warm, light, and hopeful.

- no villains required
- the world is not dangerous, it is unfinished
- math does not destroy chaos through violence
- math gives shape, balance, fairness, rhythm, and connection

NPC roles:

- child who notices patterns
- builder who needs correct totals
- farmer who understands repeated groups
- baker who needs fair fractions
- merchant who needs equal sharing

These characters turn abstract math into human needs.

## UX Principles

- one concept per tutorial beat
- animations should explain the math result
- mistakes should feel safe and reversible
- the answer should be visible after interaction, not hidden in text
- level intros should be one line, not a paragraph

## Difficulty Curve

Teach in this order:

1. recognize
2. combine
3. predict
4. optimize
5. generalize

Example for addition:

- early: choose which pair makes 5
- mid: make 8 using three numbers
- late: hit 10 in the fewest moves

This teaches understanding first and efficiency second.

## Transition Plan From Current Prototype

### Keep

- `AbstractionManager` as the chapter progression backbone
- dialogue manager as a lightweight narrative tool
- world layers as restoration reveal logic

### Replace

- free movement and interactable gating as the main game loop
- resource gathering as the primary progression
- single-solution gate checks as the main form of challenge

### Add

- puzzle board scene
- level data format
- star rating system
- restoration task system
- chapter map UI

## Suggested Production Order

1. Build a simple stage-select map
2. Build one reusable puzzle board scene
3. Implement counting chapter with 10 to 15 short levels
4. Add star rewards and one restoration district
5. Implement addition chapter using the same board with new rules
6. Add chapter-complete transitions and world art changes
7. Expand to multiplication, fractions, and division

## Immediate Implementation Target

The best next playable milestone is:

"A counting chapter vertical slice with a stage map, 10 short levels, 3-star scoring, and one restored village scene."

If that slice feels good, the rest of the game has a strong foundation.
