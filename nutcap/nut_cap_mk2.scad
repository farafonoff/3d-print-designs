// Protective cap for a hex nut, mk2 (print in TPU or PETG). mk1 is the arched version with the "minimotors" text.
// A rounded cylindrical cap with a hex pocket that slips over the nut (18 mm across flats), a conical
// lead-in (skirt) at the entry so it centres itself on the nut, a slightly domed ceiling, a flat top and
// a raised letter on the top face, readable from above: "M" (the M of the minimotors wordmark, lib_logo_m.scad) or "D" (the Dualtron logo mark, personal
// use only), chosen with logo_letter.
// Print upright (opening down, no supports): the pocket ceiling is a short bridge.

use <lib_logo_m.scad>

$fn = 96;

// ---------- Nut ----------
nut_af    = 18;     // across flats of the nut (given)
nut_h     = 12;     /* MEASURE: nut height (pocket depth) */
fit       = 0.2;    // clearance on each side of the nut (0 = exact size; negative = stretch, for TPU)
ceil_dome = 1;      // how much the inside of the top bulges up in the middle (0 = flat); the edge stays at nut_h
hex_rot   = 0;      // rotation of the hex pocket about the vertical axis (0 = flats parallel to the logo's top edge)

// ---------- Body ----------
max_od    = 30;     // outer diameter of the cap
body_h    = 16;     // height of the flat top, measured from the open end
edge_r    = 2;      // rounding of the top edge
skirt_h   = 3;      // height of the conical lead-in at the pocket entry (self-centering on the nut)
skirt_out = 1.5;    // how much wider the entry is than the nut, per side, at the open end (0 = no skirt)

// ---------- Logo ----------
logo_letter = "M";  // [M, D]
logo_w      = 22;   // width of the letter
logo_height = 0.6;  // how far the letter stands above the top
logo_sink   = 3;    // how far the letter reaches down into the cap, so it stays joined if the surface curves away
logo_bolden = 0;    // grows every edge by this much (negative = thinner)

body_r = max_od / 2;
hex_r = (nut_af + fit * 2) / 2 / cos(30);

module body(r = body_r, h = body_h, er = edge_r) {
    rotate_extrude()
        intersection() {
            square([r, h]);
            hull() {
                square([r, 1]);
                translate([r - er, h - er]) circle(er);
                square([0.01, h]);
            }
        }
}

module pocket() {
    // spherical ceiling: a cap that meets the nut_h plane at the hex corners and rises ceil_dome in the middle
    if (ceil_dome > 0) {
        dome_R = (hex_r * hex_r + ceil_dome * ceil_dome) / (2 * ceil_dome);
        intersection() {
            rotate(hex_rot) translate([0, 0, nut_h - 0.01]) cylinder(r = hex_r, h = ceil_dome + 0.01, $fn = 6);
            translate([0, 0, nut_h + ceil_dome - dome_R]) sphere(r = dome_R, $fn = 128);
        }
    }
    translate([0, 0, -0.01]) rotate(hex_rot) cylinder(r = hex_r, h = nut_h + 0.01, $fn = 6);
    // hex-shaped taper, so every flat of the nut is guided, not just the corners
    translate([0, 0, -0.01]) rotate(hex_rot)
        cylinder(r1 = hex_r + skirt_out / cos(30), r2 = hex_r, h = skirt_h + 0.01, $fn = 6);
}

// The D, traced by eye from the logo (240 x 176 units, origin at the centre, y up).
// Pointed, concave flares on the left corners, rounded right corners, square hole.
module logo_2d() {
    cx = 150; cy = 117;  // centre in the traced coordinates (image y grows downwards)
    translate([-cx, cy]) mirror([0, 1]) difference() {
        union() {
            polygon([[30, 35], [50, 31], [75, 29], [110, 29], [110, 205], [75, 205], [50, 203], [30, 199],
                     [36, 185], [42, 165], [42, 70], [36, 50]]);
            translate([110, 29]) {
                square([60, 176]);
                offset(r = 28) offset(delta = -28) square([160, 176]);
            }
        }
        translate([75, 70]) offset(r = 10) offset(delta = -10) square([135, 95]);
    }
}

module logo() {
    translate([0, 0, body_h - logo_sink])
        linear_extrude(height = logo_sink + logo_height)
            offset(delta = logo_bolden)
                if (logo_letter == "D") scale(logo_w / 240) logo_2d();
                else scale(logo_w / logo_m_width()) logo_m_2d();
}

module nut_cap() {
    difference() {
        body();
        pocket();
    }
    logo();
}

nut_cap();
