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

Caliper measurements of the original (user bought a caliper, replaces earlier photo estimates):
- Bore 22.2-22.3 mm on the original; modelled as 22.2 (`fit_clear` 0) for a snug TPU fit, tune by 0.1 after the test print.
- Lips: outer diameter 26.3 mm, width 16.3 mm between the two cutting planes (a metric width, not an angle), depth 8 mm (= width of the metal ring; 7.2 was a first caliper reading of the old rubber). Two opposite lips with straight, parallel sides, made by two rectangular cuts.
- Pattern starts exactly where the lips end, so seat length equals lip depth.
- Thick part outer diameter 29 mm (modelled as the diameter at the ends of the pattern; `bulge` adds a smooth sine-shaped swell in the middle, default +1 mm radius so ~31 mm at centre; pockets and logo engraving follow it via `body_r()` / `envelope()`; `bulge = 0` gives the straight cylinder). Cross-section oval was discussed and declined: the user meant a barrel profile along the length. The wall under the pockets is then 2.15 mm (`wall_min` lowered to 2.0).
- Pattern: hex pockets, inverted (recessed with raised ridges), deep so it wears slowly. Started at 2.6 mm cells (hex_r 1.5), scaled 1.5x at the user's request (hex_r 2.25, ~3.9 mm across flats) with the same 1.2 mm depth and ~10% wider ridges (0.88 mm).
- The earlier 15 mm lip print (25.5 mm seat) was visibly too small in the ring; not yet tested on a bar.

OpenSCAD gotcha: a top-level variable cannot reference one defined further down the file (it becomes undef), so define the source value first.

Mistakes not to repeat: the lip cuts were misread several times (sector wedges, parallel slab, "+" slots). The correct reading is two cuts at 90 degrees to the lips.

Logos: Claude and OpenAI marks (simple-icons SVGs in `logos/`) are engraved into the hex pattern (no big flat pads) at 80% of the pocket depth, with a 1.2 mm solid border that follows the logo outline and fills the pockets around it. Trademarks, personal use only.

## kindlecase
Kindle shell and a test ring, printed in PETG (Elegoo) on an Ender 3 Plus. Sliced gcode is kept locally but not committed.

## bookmarks (image-based, for the user's wife, printed in PLA)
Sources are black/white artwork in `source/` (`cat_pattern.jpeg`, `fish_pattern.jpeg`); white = material, black = cut through. `./prep_images.sh` (ImageMagick) thresholds, crops and downsizes them into `build/<name>.png` (mask) and `build/<name>_h.png` (height profile with a rounded `EDGE_R` = 0.3 mm fillet ramp from the blurred mask); both are committed so previews work. The size table at the bottom of `prep_images.sh` (h, t per bookmark) must match `h` and `t` in `<name>_bookmark.scad`.
`lib_bookmark.scad`: `bookmark()` builds the top half with `surface()` from the `_h` map, mirrors it for the bottom (rounded edges in cross-section on both faces), intersects with an extrusion of the artwork footprint traced from the same map (otherwise black pixels leave a paper-thin film), and scales everything to w x h x t. `bookmark_flat()` is the plain 2D extrusion with optional `smooth` corner rounding. Verified with a cross-section slice. Thin lace lines are about 0.7 mm at 36 mm width; PLA is brittle there. The fillet is only ~1.5 px wide at PX_H=900, so it reads as a small chamfer; raise `PX_H` for a rounder one (slower render). No potrace installed; the user is fine with the `surface()` route and with the anti-aliasing (greyscale) interpretation.
