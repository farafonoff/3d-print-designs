// Fish pattern bookmark (source/fish_pattern.jpg): fish, seaweed and an octopus
// inside a pointed frame, the black areas of the artwork are cut through the plate.
// The outline is cut from the thin black line around the source image.
// Run ./prep_images.sh after changing the source image.
use <lib_bookmark.scad>

w      = 36;    // bookmark width (mm)
h      = 176;   // bookmark length (mm)
t      = 2;   // plate thickness (mm)
hole_d = 0;     // tassel hole diameter, 0 = none
// Edges are rounded by the height map; h and t must match the table in prep_images.sh.
bookmark("build/fish_h.png", w, h, t, hole_d);
