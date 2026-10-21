// Cat pattern bookmark (source/cat_pattern.jpeg): lace-like cat and ornament,
// the black areas of the artwork are cut through the plate.
// Run ./prep_images.sh after changing the source image.
use <lib_bookmark.scad>

w      = 36;    // bookmark width (mm)
h      = 176;   // bookmark length (mm)
t      = 2;   // plate thickness (mm)
hole_d = 0;     // tassel hole diameter, 0 = none
// Edges are rounded by the height map; h and t must match the table in prep_images.sh.
bookmark("build/cat_h.png", w, h, t, hole_d);
