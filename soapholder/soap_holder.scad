// Soap holder, two kinds of part (print in PETG / PLA, no supports):
//   hook  x2  S-shaped hook for a 7 mm pipe: J-curl over the pipe (bore = pipe_d + pipe_clear), long stem,
//             bottom curl forward into a flat shelf under the dish, a long low zigzag rib on the shelf top.
//             Printed lying on its side; the shelf profile is the 2D shape of the layers and the zigzag
//             rib leans at less than 45 degrees, so no supports.
//   dish      Soap_Dish.stl on top of a flat plate that follows its bottom outline, unioned with it. The
//             plate has a zigzag cut through it at each hook. The STL itself is not touched. Printed
//             flat on the bed (the plate is the first layers), no supports.
//   The dish stands on the two shelves (plate on the shelf tops) and the zigzag ribs go into the zigzag
//   cuts, which locks it in both horizontal directions.
// Soap_Dish.stl (not ours, author/licence not recorded) is oriented with its flat back down, its low wall
// (with the hex hole) at the front and its tall wall at the back, by the stem. The dish_* values below were
// measured from that STL; re-measure them if you swap the model.
// layout = print / hook / dish / assembled / check. `check` shows only the flat plate-on-shelf contact if
// nothing overlaps.
//
// Parameters marked MEASURE are worth checking against your pipe and wall.

$fn = 64;

layout = "assembled";   // [print, hook, dish, assembled, check]

// ---------- Pipe ----------
pipe_d     = 7;      /* MEASURE: pipe outer diameter */
pipe_clear = 0.1;    // bore = pipe_d + pipe_clear

// ---------- Hook ----------
hook_w     = 16;     // strip width (along the pipe)
strip_t    = 3;      // thickness of the curls and the stem
shelf_t    = 5;      // thickness of the shelf under the dish
wrap_end   = 200;    // angle (deg) where the top curl ends; 180 = pipe equator, >180 grips below it (snap-on)
stem_len   = 90;     // straight part between the two curls
bend_r     = 6;      // centre-line radius of the bottom curl
hook_pitch = 60;     // distance between the two hooks (centre to centre)

// ---------- Plate and zigzag ----------
plate_t    = 4;      // plate thickness under the dish
plate_r    = 10;     // corner radius of the plate (the dish's bottom corners)
rib_w      = 3;      // thickness of the zigzag rib
rib_h      = 3.5;    // rib height above the shelf (less than plate_t)
dish_tol   = 0.4;    // tolerance on the dish side: the cut is the rib + dish_tol on each side (a bit more than usual, the cut opens at the first layers, where elephant foot squeezes it)
zig_amp    = 3.5;    // the zigzag swings +- this much across (along the pipe)
zig_len    = 40;     // length of the zigzag along the shelf (front-back)
zig_steps  = 6;      // number of straight pieces (keep atan(zig_len / zig_steps / (2 * zig_amp)) below 45 degrees)

// ---------- Dish (Soap_Dish.stl, measured at its centre line) ----------
dish_file        = "Soap_Dish.stl";
dish_bottom_half = 30.2;   // half depth of the flat bottom (front-back)
dish_half_y      = 45.2;   // half length of the flat bottom (along the pipe)
dish_back_top    = 39.75;  // half depth at the rim, tall wall side (back)
dish_back_clear  = 1;      // gap between the back rim and the stem

// ---------- Derived ----------
bore_r  = (pipe_d + pipe_clear) / 2;
rc      = bore_r + strip_t / 2;          // centre-line radius of the top curl
shelf_z = -stem_len - bend_r;            // centre line of the bend's end (pipe centre at 0,0)
shelf_x0 = rc + bend_r;
shelf_top = shelf_z - strip_t / 2 + shelf_t;   // the plate rests here
plate_top = shelf_top + plate_t;               // the dish's flat bottom is here
dish_cx = rc + strip_t / 2 + dish_back_clear + dish_back_top;   // dish centre in x: back rim clears the stem
shelf_end = dish_cx + dish_bottom_half;

function arc(c, r, a0, a1, n = 24) = [for (i = [0:n]) c + r * [cos(a0 + (a1 - a0) * i / n), sin(a0 + (a1 - a0) * i / n)]];

centre_line = concat(
    arc([0, 0], rc, wrap_end, 0),
    arc([rc + bend_r, -stem_len], bend_r, 180, 270),
    [[shelf_x0, shelf_z]]
);

module stroke(pts, t) {
    for (i = [0:len(pts) - 2])
        hull() for (p = [pts[i], pts[i + 1]]) translate(p) circle(d = t);
}

module hook_profile() {
    stroke(centre_line, strip_t);
    translate([shelf_x0, shelf_z - strip_t / 2]) square([shelf_end - shelf_x0, shelf_t]);
}

// zigzag centre line running front-back (x, centred on the dish), swinging along the pipe (y), centred on y = 0
function zig_pts() = [for (i = [0:zig_steps])
    [dish_cx - zig_len / 2 + i * zig_len / zig_steps, (i % 2 == 0 ? -zig_amp : zig_amp)]];

module zig2d(w) {
    pts = zig_pts();
    for (i = [0:len(pts) - 2])
        hull() for (p = [pts[i], pts[i + 1]]) translate(p) circle(d = w);
}

module hook() {
    rotate([90, 0, 0]) linear_extrude(height = hook_w, center = true) hook_profile();
    translate([0, 0, shelf_top - 0.01]) linear_extrude(height = rib_h + 0.01) zig2d(rib_w);
}

// Soap_Dish.stl: dish x -> y, dish z -> x (tall wall to the back), dish y (depth, flat back at -20) -> up
module dish_stl() {
    multmatrix([[0, 0, 1, dish_cx], [1, 0, 0, 0], [0, 1, 0, plate_top + 20], [0, 0, 0, 1]])
        import(dish_file, convexity = 10);
}

// flat plate following the dish bottom outline
module plate() {
    translate([0, 0, shelf_top])
        linear_extrude(height = plate_t + 0.5)    // 0.5 mm into the dish floor so the union is solid
            translate([dish_cx, 0]) offset(r = plate_r) square([2 * (dish_bottom_half - plate_r), 2 * (dish_half_y - plate_r)], center = true);
}

// the STL unioned with the plate; the cut stops at the dish floor, so its top 0.5 mm stays closed
module dish() {
    dish_stl();
    difference() {
        plate();
        for (s = [-1, 1]) translate([0, s * hook_pitch / 2, shelf_top - 1]) linear_extrude(height = plate_t + 1) zig2d(rib_w + 2 * dish_tol);
    }
}

module hooks() {
    for (s = [-1, 1]) translate([0, s * hook_pitch / 2, 0]) hook();
}

if (layout == "hook") hook();
else if (layout == "dish") dish();
else if (layout == "check") intersection() { hooks(); dish(); }
else if (layout == "print") {
    // hooks lying on their side (profile in the XY plane, width up)
    for (i = [0, 1]) translate([i * (shelf_end + 30), 0, hook_w / 2]) rotate([-90, 0, 0]) hook();
} else {
    hooks();
    dish();
}
