# Repository Guidelines

## Project Structure & Module Organization

Reset Run is a Godot 4 runner prototype. `project.godot` configures the project and launches `scenes/game.tscn`. Gameplay lives in `scripts/game.gd`; `scripts/resetbot.gd` controls the reusable character visuals in `scenes/resetbot.tscn`. Animation resources are in `scenes/resetbot_frames.tres`, with sprite sheets and backgrounds under `images/`. `tools/` contains validation, preview, and asset-processing scripts; `tools/previews/` stores visual references. Consult `docs/GUIA_PROYECTO.md` for requirements, decisions, and outstanding work.

## Build, Test, and Development Commands

Run these from the repository root with Godot available as `godot` on PATH (substitute your executable path if needed). The project declares Godot 4.7; the README records validation with 4.7.2.

- `godot --editor --path .`: open the project; press F5 to play.
- `godot --path .`: run the main scene directly.
- `godot --headless --editor --path . --import`: import assets and exit.
- `godot --headless --path . --script tools/check_game.gd`: run gameplay assertions.
- `python tools/build_frames.py`: regenerate `scenes/resetbot_frames.tres` using the `no_outline` sprite variant; add `--original-outline` for `transparent` sprites.

No export presets or dedicated build pipeline are checked in.

## Coding Style & Naming Conventions

Follow existing GDScript: tabs for indentation, `snake_case` functions and variables, `UPPER_SNAKE_CASE` constants, and type annotations where practical. Keep filenames lowercase with underscores. Preserve LF endings as specified in `.gitattributes`. No formatter or linter configuration is included. Keep gameplay logic separate from character animation methods; update the frame generator when changing generated animation resources.

## Testing Guidelines

Tests use Godot assertions in `tools/check_game.gd`; there is no separate testing framework or coverage threshold. Extend this check for gameplay changes, covering speed progression, frame anchors, jumping, damage, Game Over, and restart. Run asset import before validation on a fresh checkout. Visually inspect animation changes in the editor: automated checks cannot establish correct cropping, foot alignment, or appearance.

## Commit & Pull Request Guidelines

The current history contains one descriptive, imperative commit beginning with “Add”; use similarly concise, action-oriented subjects. Pull requests should describe the behavior changed, validation performed, and relevant issue or backlog IDs. Include screenshots or animation captures for visual changes.

## Asset & Configuration Rules

Preserve supplied sprite originals, character proportions, colors, and RESET logo. Retain animation frame order and nearest-neighbor filtering. Keep `.godot/`, exported builds, and credentials out of Git, following `.gitignore`.

## Public GitHub Presentation

Keep public-facing GitHub content focused on the finished game and its players. Do not include development history, prototype status, pending implementation work, Godot references, engine details, build commands, or other development information in the README or public game presentation. Write `README.md` as the player guide for a finished game: explain the objective, controls, how to start playing, lives, scoring, Game Over, and restarting. Keep contributor and technical instructions in internal documentation rather than linking them from the player-facing README. Describe only playable features; do not present planned features as available.
