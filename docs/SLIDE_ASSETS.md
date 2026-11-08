# Slide sprite preparation

## Active low posture

The active animation uses `images/character/no_outline/slide_low_resetbot.png` (also provided in `transparent/`). It replaces the seated slide with a nearly horizontal pose at the user's request. The original supplied sheet and the first extracted atlas remain intact.

Built-in imagegen changed the body poses while retaining the mascot identity and uniform proportions; no nonuniform runtime scaling is used. The raw transparent result is retained at `tools/alpha_masks/slide_low_source.png`. `tools/prepare_low_slide.ps1` removes near-transparent specks and preserves the generated RGB. `tools/build_frames.py` uses the measured gaps between the eight characters on the 2172 × 724 sheet. The 200-pixel head-width reference maps uniformly to the existing 102-pixel display width.

The held pose is about 59 pixels tall and at least 125 pixels long. Only poses three through five receive the 52-pixel-tall, 110-pixel-wide collision rectangle. Entry and recovery use the normal rectangle, so merely pressing the button does not immediately grant low clearance. Holding/releasing the three controls and interrupting with a jump work as before. Preview: `tools/previews/slide_frames.png`.

### Exact low-posture prompt

Tool: built-in imagegen, transparent edit mode. Reference: the user's original sliding sheet.

> Edit target: supplied Resetbot eight-frame slide sprite sheet. User explicitly requests a MUCH LOWER, MORE STRETCHED-OUT slide, actually lying nearly flat to pass below low overhead obstacles, rather than the current upright seated slide. Create an updated eight-frame atlas on an EXACT 2172x724 transparent RGBA canvas, eight equal horizontal cells. Keep Resetbot's identity, original black angular head, red eye, white RESET chest badge, white gloves/shoes and red joints exactly recognizable. Preserve head proportions/size, colors, pixel-art style, fine 1-2px outline; DO NOT squash, scale anisotropically or shrink the head/body to fake crouching. Change the body POSES anatomically: recline the torso almost horizontal, extend legs forward to the right, lower the head close to ground level. Pose 1: enter crouch; pose 2: lean far back; poses 3,4,5: full extremely low extended slide lying back nearly flat, shoulders/head and heels all close to floor, entire silhouette only about 95 pixels tall at head width 160 pixels, extended silhouette roughly 240 pixels wide. Pose 6: start rising; poses 7,8: recover upright. ALL EIGHT must appear left-to-right in the original order. All poses have consistent head width approx160px, feet on common baseline y530. Keep each pose entirely within its own 271.5-pixel-wide cell, with comfortable transparent gaps, no cut limbs. No header, no captions, no labels, no background, no ground shadows, no detached speed streaks. TRUE transparency. The central poses must look visibly horizontal and far lower than the reference, without changing the mascot design or deleting limbs.

## Original extraction (retained reference)

Original, unchanged: `images/character/deslizarse.png` (1464 × 306).

First prepared atlases: `images/character/no_outline/slide_resetbot.png` and `images/character/transparent/slide_resetbot.png`. The eight original poses remain in order. Their former 145-pixel source head-width reference matched the existing 102-pixel display head width. Each frame uses the same bottom-bound anchor as the other animations. Nearest filtering is retained.

Built-in imagegen produced the extraction mask at `tools/alpha_masks/slide.png` (2172 × 724). The generated canvas fits and centers the original strip at uniform scale. `tools/prepare_slide.ps1` maps this alpha back to the original coordinates, keeps the largest character component in each column, removes blue floor-shadow remnants near the feet and copies RGB only from the unchanged source. Detached marks are excluded to keep the silhouettes and ground anchors clean.

Regenerate with `tools/prepare_slide.ps1`, then `python tools/build_frames.py`. Inspect all eight poses against dark and light backgrounds with `godot --path . --script tools/preview_double_jump.gd -- slide`; output: `tools/previews/slide_frames.png`.

Holding Down, Ctrl or right mouse pauses the slide on pose five. Releasing resumes the remaining three recovery poses. A jump interrupts sliding; restarting and damage clear it. The collision rectangle is lower and wider while sliding, but still collides with ground obstacles.

## Exact imagegen prompt

Tool: built-in imagegen, transparent edit mode. Edit target: the original sliding sheet.

> Use case: background-extraction. Edit target: the supplied Resetbot slide animation sheet. Prepare a precise transparent extraction ALPHA MASK for all EIGHT existing poses. Preserve the EXACT original 1464 by 306 canvas, all pose pixel coordinates, scale, order and proportions. Remove the dark blue background, DESLIZARSE title, '(8 frames)' label and ALL floor shadows. Keep the original eight characters and the small light motion streaks beside the sliding poses. Thin only the thick outermost black border to a fine 1-2 pixel edge while preserving the interior black head and limbs, white gloves and shoes, red eye and RESET chest logo. No redesign, new poses, missing poses, movement of poses, repositioning, cropping, resizing or deformation. Actual RGBA transparency, no painted checkerboard and no white fringe. Exact coordinates are essential because the alpha will be composited with the untouched original RGB pixels.
