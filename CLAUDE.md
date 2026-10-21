# vibe-design: working notes

Parametric 3D-printable designs in OpenSCAD (the user may write "openscada"). One folder per design. The `.scad` files are the primary artifact; STLs are exports and may be stale. Remote: `git@github.com:farafonoff/3d-print-designs.git`.

## Conventions
- Parameters live at the top of the main `.scad`, grouped in `// ---------- Section ----------` blocks. Mark measurements the user still has to verify with `[MEASURE]`.
- `test_*.scad` files `use <main.scad>` and intersect `grip()`-style modules with a box to cut a small test piece. They must not override parameters; tuning happens only in the main file.
- Each `.scad` starts with a leading `//` comment block describing it; keep it current, `previews.sh` copies it into the folder README. Each project folder has `previews.sh` (renders every `.scad` except `test*.scad` and `lib*.scad` (helper libraries) to `previews/` and refreshes the generated section of the folder's `README.md`). The `previews.sh` scripts are identical copies: change all of them. `*.gcode` is git-ignored.
- The user checks designs visually in OpenSCAD. Don't render or open previews unless asked, except to validate a script or fix an error they pasted.
- Paste of OpenSCAD console output usually means "fix this". "No top level geometry" means the final module call is missing.
- Commit or push only when asked. Commit trailer: see the session attribution reminder.

## bikegrips (TPU lock-on grips, sleeve only)
User reuses the metal lock rings from a worn-out lock-on grip and prints only the rubber sleeve in TPU. `lockon_grip.scad` is the whole design; `test_grip.scad` prints the bottom 11 mm (lips + one hex row) to check fit.

Measured / confirmed by the user:
- Bar bore exactly 22.2 mm (`fit_clear = 0`).
- Ring seat diameter 25 to 26 mm (tolerance +-1), currently 25.5.
- Lips: seat wall is cut back 8 mm at both ends by two rectangular cuts, leaving two opposite lips with straight, parallel sides. The distance between the two cutting planes is exactly 15 mm (a metric width, not an angle).
- Pattern must start exactly where the lips end, so seat length equals lip depth (8 mm).
- Pattern: small hex pockets (cells 2 to 3 mm), inverted (recessed with raised ridges), deep so it wears slowly.
- Outer diameter is uncertain: set to 33 from a vague remark; 30 to 31 is probably closer. Verify with calipers.

Mistakes not to repeat: the lip cuts were misread several times (sector wedges, parallel slab, "+" slots). The correct reading is two cuts at 90 degrees to the lips.

Logos: Claude and OpenAI marks (simple-icons SVGs in `logos/`) are engraved into smooth round pads. Trademarks, personal use only.

## kindlecase
Kindle shell and a test ring, printed in PETG (Elegoo) on an Ender 3 Plus. Sliced gcode is kept locally but not committed.

## bookmarks (image-based, for the user's wife, printed in PLA)
Sources are black/white artwork in `source/` (`cat_pattern.jpeg`, `fish_pattern.jpeg`); white = material, black = cut through. `./prep_images.sh` (ImageMagick) thresholds, crops and downsizes them into `build/<name>.png` (mask) and `build/<name>_h.png` (height profile with a rounded `EDGE_R` = 0.3 mm fillet ramp from the blurred mask); both are committed so previews work. The size table at the bottom of `prep_images.sh` (h, t per bookmark) must match `h` and `t` in `<name>_bookmark.scad`.
`lib_bookmark.scad`: `bookmark()` builds the top half with `surface()` from the `_h` map, mirrors it for the bottom (rounded edges in cross-section on both faces), intersects with an extrusion of the artwork footprint traced from the same map (otherwise black pixels leave a paper-thin film), and scales everything to w x h x t. `bookmark_flat()` is the plain 2D extrusion with optional `smooth` corner rounding. Verified with a cross-section slice. Thin lace lines are about 0.7 mm at 36 mm width; PLA is brittle there. The fillet is only ~1.5 px wide at PX_H=900, so it reads as a small chamfer; raise `PX_H` for a rounder one (slower render). No potrace installed; the user is fine with the `surface()` route and with the anti-aliasing (greyscale) interpretation.
