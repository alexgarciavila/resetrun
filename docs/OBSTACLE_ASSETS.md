# Obstacle assets and gameplay

The six supplied 1254 × 1254 originals in `images/obstacles/` remain unchanged. Built-in imagegen extracted their alpha masks into `tools/alpha_masks/obstacles/`; exact prompts are saved in that directory's `prompts.json`. `tools/prepare_obstacles.ps1` composites original RGB using alpha ≥ 128, splits multi-group sheets and crops with two pixels of transparent padding.

## Prepared sprites

All runtime sprites are in `images/obstacles/prepared/`:

| Sprite | Source | Role |
| --- | --- | --- |
| `computer.png` | computer | Single jump |
| `peripherals.png` | perifericos | Single jump |
| `laptops_router.png` | camrouter, lower group | Single jump |
| `printer.png` | printer, lower group | Single jump |
| `tower.png` | hightower | Double jump |
| `camera.png` | camrouter, upper group | Slide scanner |
| `cables.png` | printer, upper group | Slide scanner |
| `repair_gate.png` | repair_station | Slide scanner |

Connected peripheral groups remain grouped; the separated upper/lower objects get independent textures. Backgrounds and cast shadows are removed. The original scan cone is excluded from the camera extraction because its gameplay field is rendered separately.

## Gameplay geometry

`scripts/obstacle_catalog.gd` defines uniform sprite scaling, type, clearance, collision region and Catalan action cue. Ground equipment is 54–82 pixels high; the 220-pixel tower exceeds the single-jump limit. Suspended devices have an explicit red scanning region reaching the ceiling and leave 66 pixels clear above the floor. This visible region prevents bypassing the slide challenge with a jump; decorative brackets and cables do not introduce hidden collision boxes. The fully extended player has 52-pixel clearance, so entry/recovery poses still collide.

Obstacle positions and collision boxes use the current world's ground line, including during Endless transitions. One global shuffled bag contains every individual obstacle exactly once. The same obstacle cannot repeat across bag boundaries. This gives equal frequency to individual assets rather than maneuver categories. Restart clears the bag and previous ID.

## Additional obstacle and pacing

`images/obstacles/prepared/power_crate.svg` is an original pixel-style energy crate with transparent padding. It renders at 78 pixels high and requires a single jump, using the same outline and cue treatment as the supplied equipment. The catalog preloads it and the web export preset explicitly includes it.

Spacing uses a 500–580 pixel gap plus the preceding sprite width. Tall double-jump obstacles receive a fixed additional 280 pixels for landing. These distances never scale with speed: the countdown is consumed by distance traveled, using normalized START_SPEED units. Faster running reduces arrival time without increasing separation.

## Checks

- `tools/check_obstacles.gd` simulates correct/incorrect moves for all eleven assets at 360 and 720 px/s, plus ten full fair-selection cycles, distance-based spacing, transparent padding and reset.
- `tools/check_game.gd` covers slide posture, damage, restart, double jump and world transitions.
- `tools/check_obstacles_web.cjs` checks exported loading and captures live introductory obstacles.
- `tools/preview_obstacles.gd` renders the three challenge levels into `tools/previews/obstacles.png`.

The web export preset explicitly includes the new catalog and all eleven textures, avoiding missing-preload failures in release builds.

## Readability treatment

Scenery is darkened by 18% before drawing the hazards, character and UI. The original obstacle pixels retain their colors. At startup, native image operations cache white alpha silhouettes; drawing these at screen-space offsets creates a 1.25-pixel pale outline with a 2.5-pixel dark outer rim. This keeps contrast on both light and dark worlds without editing any sprite files or altering collision geometry.

Action badges retain arrows/text and add yellow (jump), orange (double jump) and turquoise (slide) colors. Busy-world previews can be generated with `tools/preview_obstacles.gd -- taller2` or `-- magatzem2`.

## Single-jump window

Every variant, including the gate, has a random position in the global shuffled bag. No particular variant is forced first.

`jump_gate.svg` is a code-native mechanical laser gate with a 100 × 300 canvas. It joins the jump pool and displays `↑ NOMÉS UN SALT`. Two independent collision rectangles share a central 40-pixel column: the bottom occupies the lowest 45 pixels; the upper field extends from 250 pixels above ground to the ceiling. Red bands visibly match both regions, while turquoise arrows identify the safe middle window. Both collision rectangles stay relative to each world's floor, including in Endless mode. Tests verify a single jump clears it at initial and maximum speed, while standing, sliding and a double jump collide.

## Frame pacing

Physics stays fixed-step; custom background, foreground streaks and obstacle drawing interpolate each rendered frame. Scenery interpolation wraps across tile boundaries, while collision geometry stays at its simulation position. Character transforms use built-in physics interpolation. F3 toggles measured game FPS, average frame time and worst frame time over each one-second sample. Run `node tools/check_fps_web.cjs` to collect browser frame intervals and capture the game counter; headless results do not establish physical-display performance.
