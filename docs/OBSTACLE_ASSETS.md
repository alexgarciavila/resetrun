# Obstacle assets and gameplay

## Organization

Playable sprites live in `images/obstacles/prepared/<world>/`. Supplied source artwork is preserved unchanged in `images/obstacles/sources/<world>/`; source sheets are named `sheet.png`. Source artwork is not included in the web export.

There are 39 playable source sprites plus six composed passage variants (45 catalog entries). Each world family has six new sprites and its own passage variant, plus these retained sprites:

| Sprite | Folder and world | Role |
| --- | --- | --- |
| evil_ai_robot.png | datacenter | Double jump |
| peripherals.png | taller | Single jump |
| printer.png | oficina | Single jump |

Magatzem 2 and Taller 2 share the assets of their respective families. All other legacy prepared sprites have been removed from the catalog, export and playable asset folders.

## Preparation

`tools/new_obstacles.json` records the 36 new names and actions. `python3 tools/prepare_new_obstacles.py` splits the transparent sheets in `tools/alpha_masks/new_obstacles/`, crops each piece and adds transparent padding (requires Pillow). `tools/prepare_obstacles.ps1` rebuilds only the retained peripherals and printer from the original RGB and the alpha masks in `tools/alpha_masks/obstacles/`. The robot retains its generated transparent artwork; see `EVIL_AI_ROBOT_ASSET.md`.

## Geometry and selection

`scripts/obstacle_catalog.gd` defines textures, floor-relative collision boxes, heights and Catalan action cues. Low obstacles render at 54–82 pixels high, tall obstacles at 180; the robot renders at 220. Each world has at least two ceiling and two double-jump variants. Keyboard/headphones, network equipment, a motherboard, a bench and a planter also serve as hanging hazards; the monitor, tool case and bollard are enlarged for double jumping. Suspended devices leave 66 pixels below them and hang from visible cables, without a red scanning field. Both the device and its supporting cable column block jumping over the slide challenge.

Each world has its own shuffled bag. Every eligible obstacle appears once per bag, with no immediate repeat across bag boundaries. World changes discard the remaining bag while retaining obstacles already on screen. Restart clears selection state. Spacing uses a 500–580 pixel gap plus sprite width, with another 280 pixels after double-jump obstacles; distance consumed tracks actual running speed.

## Validation and export

- `tools/check_obstacles.gd` checks all 45 variants, transparent padding, required maneuvers at 360 and 720 px/s, world assignments and shuffled bags.
- `tools/check_game.gd` checks jumping, sliding, damage, restart and world transitions.
- `tools/preview_obstacles.gd -- <world>` renders a sample of that world's hazards into `tools/previews/`.

`export_presets.cfg` explicitly includes all 39 playable textures. After changing a path or adding a texture, update this list and verify loading and gameplay in an actual browser.

Each composed passage reuses two textures from its world: a 45-pixel floor piece and an overhead piece ending 250 pixels above ground. The opening admits the normal jump arc; tests verify that standing, sliding and an early double jump collide at both tested speeds. The upper piece hangs from cables, without laser fields or new bitmap files.

The game draws pale inner and dark outer silhouettes for contrast without editing sprite colors. Yellow, orange and turquoise badges indicate jump, double jump and slide respectively. Physics uses fixed steps; visible positions interpolate between those steps.
