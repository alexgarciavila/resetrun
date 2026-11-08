# Double-jump asset preparation

The game now reuses the regular upright jump animation for the second impulse, as requested. The processed spinning atlas below is retained as an unused source asset; it is not played during double jumps.

- Original, unchanged: `images/character/doble salto giratorio.png` (1672 × 941).
- Built-in imagegen extraction: `tools/alpha_masks/double_jump.png`.
- Runtime atlas: `images/character/no_outline/double_jump_resetbot.png`.
- Equivalent transparent variant: `images/character/transparent/double_jump_resetbot.png`.
- All-eight-frame visual check: `tools/previews/double_jump_frames.png`.

`tools/prepare_double_jump.ps1` takes the generated alpha at a threshold of 128 and copies RGB exclusively from the original sheet. This preserves the original drawing, colors and logo; the original is never overwritten. `tools/build_frames.py` retains eight poses in their original order and uses measured column boundaries without resizing the sheet. Runtime scaling matches the existing 102-pixel head-width reference, and the lower-alpha bound provides the same virtual ground anchor as the other animations. Nearest filtering remains enabled.

The eight-frame animation is timed to the remaining flight after the second impulse. Physical height is applied once by the controller; the elevation within the sheet is canceled by the per-frame anchor. A second press during ascent or descent gives a stronger upward impulse; a third press is ignored until landing.

## Imagegen prompt

Tool: built-in imagegen, edit mode, transparent background enabled. Edit target: the original double-jump sheet.

> Use case: background-extraction. Edit target: this exact Resetbot double-jump sprite sheet. Extract all EIGHT supplied poses to a genuinely transparent RGBA background. Keep the EXACT original canvas size, pixel coordinates, frame order, scale and placement of all 8 poses. Remove the dark blue background, ALL text and labels including the DOBLE SALTO header, all floor shadows and detached marks below the feet. Preserve the complete body, gloves, shoes, red eye, chest RESET logo, exact pose and original colors in each of the 8 frames. Keep the white spin swooshes around poses 6 and 7 as transparent isolated motion effects. Thin ONLY the thick outermost black silhouette border to a fine 1-2 pixel edge, preserve interior black head and limbs; no white fringe. Do not redraw, reshape, deform, add poses, omit poses, move poses, or reposition any part. Image is a game animation atlas: coordinates must stay fixed. Actual transparency, no checkerboard painted in image.
