// Glass cup holder with handle (replacement for a broken orange plastic one).
// A scalloped, tapered cradle with round windows hugs the lower part of a
// tapered glass; a flat strap handle leaves the cradle, runs up and outward,
// bends over and ends in a horizontal arm that crosses the rim and drops into
// the glass as a forked hook: two prongs straddle the glass wall, one inside and
// one outside (like the original, whose tip broke off).
// All glass dimensions are estimates from a photo: parameters marked [MEASURE]
// still need checking with calipers. Tune fit only via `clear` and `hook_clear`.
//
// Print upright (cradle floor on the bed), handle toward +X. PETG or ASA;
// the strap is thin, so print it with 4+ perimeters.

$fn = 120;

// ---------- Glass (outside of the cup) ----------
glass_h      = 85;     // [MEASURE] height of the glass, bottom to rim
glass_d_bot  = 58;     // [MEASURE] outer diameter at the very bottom
glass_d_top  = 80;     // [MEASURE] outer diameter at the rim

// ---------- Cradle ----------
clear        = 0.3;    // radial gap between glass and cradle (0 = line to line)
cradle_h     = 27;     // height of the cradle wall
wall         = 2.4;    // cradle wall thickness
floor_t      = 2.4;    // floor thickness
scallops     = 8;      // number of scallops on the top edge
scallop_r    = 6.5;    // radius of each scallop cut
window_d     = 11;     // round window diameter (0 = none)
window_z     = 11;     // window centre height above the floor
floor_hole_d = 18;     // hole in the floor (0 = none)

// ---------- Handle ----------
handle_w     = 11;     // strap width (along Y)
handle_t     = 4.5;    // strap thickness
handle_out   = 34;     // how far the loop sticks out of the cradle
handle_start = 8;      // height where the strap leaves the cradle
bend_r       = 17;     // radius of the bend at the top of the strap
rim_gap      = 1.0;    // gap between rim top and the underside of the arm
hook_depth   = 9;      // how far both prongs drop below the rim
glass_wall   = 2.0;    // [MEASURE] glass wall thickness at the rim
hook_clear   = 0.4;    // gap between hook tip and inside of the glass; smaller = holds tighter
prong_t      = 3.2;    // thickness of each of the two prongs
hook_t       = 5;      // arm thickness above the rim

// ---------- Helpers ----------
function glass_r(z) = (glass_d_bot + (glass_d_top - glass_d_bot) * z / glass_h) / 2;

// Solid of revolution following the glass taper, offset by `off`, from z0 to z1.
module glass_solid(off, z0, z1) {
    rotate_extrude()
        polygon([[0, z0], [glass_r(z0) + off, z0], [glass_r(z1) + off, z1], [0, z1]]);
}

module cradle() {
    difference() {
        glass_solid(clear + wall, 0, cradle_h);
        translate([0, 0, floor_t]) glass_solid(clear, -0.01, cradle_h + 1);
        if (floor_hole_d > 0) translate([0, 0, -1]) cylinder(d = floor_hole_d, h = floor_t + 2);
        // scalloped top edge
        for (i = [0 : scallops - 1])
            rotate([0, 0, (i + 0.5) * 360 / scallops])
                translate([glass_r(cradle_h) + clear + wall / 2, 0, cradle_h + scallop_r * 0.35])
                    rotate([0, 90, 0]) cylinder(r = scallop_r, h = wall * 4 + 10, center = true);
        // round windows between the scallops
        if (window_d > 0)
            for (i = [0 : scallops - 1])
                rotate([0, 0, i * 360 / scallops])
                    translate([0, 0, window_z]) rotate([0, 90, 0])
                        cylinder(d = window_d, h = 100);
    }
}

// Strap centre line in the XZ plane (x measured from the glass axis).
// Ends at the inner prong; the outer prong is added separately (see prongs()).
function strap_pts() =
    let(xc    = glass_r(handle_start) + clear + wall / 2,
        xo    = xc + handle_out,
        zt    = glass_h + rim_gap + hook_t / 2,      // centre line of the horizontal arm
        zb    = glass_h - hook_depth,
        xin   = glass_r(zb) - glass_wall - hook_clear - prong_t / 2,
        bend  = [for (a = [0 : 15 : 90])
                    [xo - bend_r + bend_r * cos(a), zt - bend_r + bend_r * sin(a)]])
    concat(
        [[xc, handle_start + 4],
         [xc + handle_out * 0.5, handle_start + 14],
         [xo, zt - bend_r]],
        bend,
        [[xin + 6, zt - 0.5],
         [glass_r(glass_h) - glass_wall - hook_clear - prong_t / 2, zt - 1],
         [xin, zb]]);

// Two prongs in the plane of the strap: one inside the glass, one outside,
// so the hook clamps the rim wall from both sides (as on the original).
function outer_prong_pts() =
    let(zb = glass_h - hook_depth,
        zt = glass_h + rim_gap + hook_t / 2)
    [[glass_r(glass_h) + hook_clear + prong_t / 2, zt - 1],
     [glass_r(zb) + hook_clear + prong_t / 2, zb]];

module strap_path(p, d, w) {
    rotate([90, 0, 0]) linear_extrude(height = w, center = true)
        for (i = [0 : len(p) - 2])
            hull() {
                translate(p[i])     circle(d = d, $fn = 24);
                translate(p[i + 1]) circle(d = d, $fn = 24);
            }
}

module strap() {
    p = strap_pts();
    n = len(p);
    strap_path(concat([for (i = [0 : n - 3]) p[i]]), handle_t, handle_w);
    // arm and inner prong are thinner (prong_t), the arm itself stays handle-thick
    strap_path([for (i = [n - 3 : n - 1]) p[i]], prong_t, handle_w);
    strap_path(outer_prong_pts(), prong_t, handle_w);
}

module cup_holder() {
    union() {
        cradle();
        strap();
    }
}

cup_holder();
