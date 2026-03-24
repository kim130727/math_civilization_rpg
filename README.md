# Math Civilization Puzzle

Godot 4 based puzzle game prototype.

The project is pivoting from a field-exploration RPG into a mobile-first puzzle game where players naturally learn math abstractions by solving short, satisfying puzzle stages and rebuilding the world.

## New Direction

- Core genre: casual puzzle game
- Reference feel: restore-and-progress structure similar to mobile renovation puzzle games
- Core fantasy: math is not a school subject, but a tool that repairs, organizes, and expands the world
- Learning flow: count -> add -> multiply -> fractions -> divide -> advanced abstractions

## Core Loop

1. Clear a short puzzle stage
2. Earn stars, resources, or concept fragments
3. Restore part of the world
4. Unlock a new math idea through play
5. Use the new idea in later puzzle mechanics

## Design Goals

- Teach math through repeated play, not long explanations
- Make every new concept visible in the world
- Keep stages short and mobile-friendly
- Reward experimentation and pattern recognition
- Build a strong sense of progress through restoration and unlocks

## Current Project State

The existing implementation still contains the earlier RPG-style prototype:

- player movement and interaction
- world objects and dialogue
- abstraction unlock manager
- early gate/resource progression

These systems are now best treated as prototype references while the project transitions to a puzzle-first structure.

## Suggested Next Build Steps

1. Replace movement-centric main scene with a puzzle hub + stage flow
2. Build a reusable puzzle board scene
3. Add chapter progression for counting, addition, and multiplication
4. Add star rewards and restoration tasks
5. Convert abstraction unlocks into puzzle mechanic unlocks

## Main Scene

- `res://main/Main.tscn`

## Docs

- `res://GAME_DESIGN.md`
