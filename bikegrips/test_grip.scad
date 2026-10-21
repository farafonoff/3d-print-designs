// Test piece: the full grip, cut down to one ring end (lips + one row of hex pockets).
// `use` pulls in grip() with its own parameters; nothing is overridden here.
use <lockon_grip.scad>

cut_h = 15;   // z height to keep: 8 mm lips + one hex row (~3 mm)

intersection() {
    grip();
    translate([-50, -50, -1]) cube([100, 100, cut_h + 1]);
}
