// Protective cap for a hex nut, mk1 (print in TPU or PETG), after a rubber "minimotors" cap. mk2 has a flat top and a logo mark.
// A rounded cylindrical cap with a hex pocket that slips over the nut (18 mm across flats), a conical
// lead-in (skirt) at the entry so it centres itself on the nut, a slightly domed ceiling, and an arch: a flat
// band that stands proud of the cap, runs over the top and down both sides to the open end, like the ridge on
// the original rubber cap. The label "minimotors" is raised on top of the arch, readable from above.
// Print upright (opening down, no supports): the pocket ceiling is a short bridge.

$fn = 96;

// ---------- Nut ----------
nut_af    = 18;     // across flats of the nut (given)
nut_h     = 12;     /* MEASURE: nut height (pocket depth) */
fit       = 0.2;    // clearance on each side of the nut (0 = exact size; negative = stretch, for TPU)
ceil_dome = 1;      // how much the inside of the top bulges up in the middle (0 = flat); the edge stays at nut_h
hex_rot   = 0;      // rotation of the hex pocket about the vertical axis (0 = flats parallel to the text)

// ---------- Body ----------
max_od    = 30;     // limit on the overall outer diameter, arch included
body_h    = 16;     // height of the flat top, measured from the open end
edge_r    = 2;      // rounding of the top edge
skirt_h   = 3;      // height of the conical lead-in at the pocket entry (self-centering on the nut)
skirt_out = 1.5;    // how much wider the entry is than the nut, per side, at the open end (0 = no skirt)

// ---------- Arch ----------
panel_w   = 8.5;    // arch width
panel_h   = 1.2;    // how far the arch stands proud of the cap

// ---------- Label ----------
label     = "minimotors";
font      = "Liberation Sans:style=Bold";
text_size = 2.8;    // letter height
text_height = 0.6;  // how far the letters stand above the top
text_bolden = 0;    // grows every stroke by this much on each side (0.1-0.3 for bolder letters)
text_sink = 3;      // how far the letters reach down into the arch, so they stay joined if the surface curves away

body_r = max_od / 2 - panel_h;  // cap radius; the arch adds panel_h on top of it
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

module arch() {
    intersection() {
        body(body_r + panel_h, body_h + panel_h, edge_r + panel_h);
        cube([2 * (body_r + panel_h) + 2, panel_w, 2 * (body_h + panel_h)], center = true);
    }
}

module label_text() {
    translate([0, 0, body_h + panel_h - text_sink]) linear_extrude(height = text_height + text_sink)
        offset(delta = text_bolden)
            text(label, size = text_size, font = font, halign = "center", valign = "center");
}

module nut_cap() {
    difference() {
        union() { body(); arch(); }
        pocket();
    }
    label_text();
}

nut_cap();
