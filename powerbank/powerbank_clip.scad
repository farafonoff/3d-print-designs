// Cable wrap holder for a power bank (print in PETG; TPU for a softer snap-in).
// A sleeve slides over the power bank from one end, like a ring around its cross-section: a front plate,
// two sides that follow the rounded corners, and a narrow lip on the back so it cannot fall off.
// Bottom to top along the sleeve:
//   USB-C zone    three snap-in clips in a row on the front plate (neighbours share a wall), plugs point down
//   wrap zone     the cable is wound around the outside of the sleeve
//   USB-A zone    three snap-in clips in a row, plugs point up
// Each side wall carries a comb of cable channels (one per turn, neighbours share a wall): the cable is
// wound around the sleeve and each turn is pressed into its channel through a narrow opening.
// Print standing up (sleeve axis along Z), no supports: the comb walls and channel openings slope up by
// comb_angle (45 degrees) going outwards, and the USB-A clips start with a 45 degree ramp from the plate.
//
// Parameters marked (measure) are worth checking against your power bank, cable and plugs.

$fn = 64;

// ---------- Power bank ----------
pb_w     = 77;     // (measure) width
pb_t     = 22.7;   // (measure) thickness
pb_r     = 4;      // (measure) radius of the rounded long edges, in cross-section
fit      = 0;      // clearance on each side: 0 = exact size, and printed holes run 0.1-0.2 small, so it sits snug; negative = a little stretch (TPU)

// ---------- Sleeve ----------
wall      = 2.4;   // side walls
front_t   = 2.4;   // front plate
back_t    = 2;     // lips on the back
back_lip  = 6;     // how far each lip reaches over the back face

// ---------- Cable wrap zone ----------
threads   = 6;     // turns of cable the wrap zone holds

// ---------- Side cable channels ----------
cable_d   = 4;     // (measure) cable diameter
slot_open = 3;     // width of the opening, narrower than the cable so it snaps in
ch_clear  = 0.2;   // channel is cable_d + ch_clear wide
ch_wall   = 1.6;   // channel wall (also between neighbouring channels)
comb_angle = 45;  // slope of the comb walls and channel openings, degrees above horizontal (45 = the printable limit)
ch_len    = 10;    // length of a channel along the side wall (across the power bank thickness)

// ---------- Plug clips ----------
// Plugs lie flat on the plate: w across the plate, t = height above it (the plug body / overmould, not just the metal).
plug_a_w  = 14.5;  // (measure) USB-A plug body width
plug_a_t  = 8;     // (measure) USB-A plug body thickness
plug_c_w  = 12;    // (measure) USB-C plug body width
plug_c_t  = 6.5;   // (measure) USB-C plug body thickness
plug_fit  = 0.3;   // clearance around the plug
plug_wall = 1.6;   // clip wall
plug_grip = 0.8;   // how far each lip of the opening overlaps the plug (more = tighter snap)
plug_len  = 12;    // clip length along the plug
plug_n    = 3;     // clips per zone, side by side sharing walls
zone_gap  = 3;     // gap between a plug zone and the wrap zone

// ---------- Derived ----------
xe      = pb_w / 2 + fit + wall;           // half width of the sleeve outside
out_r   = pb_r + fit + wall;               // outer corner radius
py      = pb_t + fit + front_t;            // top of the front plate
ch_d    = cable_d + ch_clear;
slot_v  = slot_open / cos(comb_angle);     // vertical size of a channel opening (it slopes, so it is measured across)
tooth_v = ch_wall / cos(comb_angle);       // vertical thickness of a comb wall
pitch   = max(ch_d + ch_wall, slot_v + tooth_v);   // distance between channels
hb      = max(ch_d / 2 + ch_wall, slot_v / 2 + tooth_v);   // first channel centre above the comb bottom
wrap_h  = 2 * hb + (threads - 1) * pitch;  // height of the comb at the side wall
z_f0    = plug_len + zone_gap;             // bottom of the wrap zone
z_f1    = z_f0 + wrap_h;                   // top of the wrap zone
z_a     = z_f1 + zone_gap;                 // bottom of the USB-A clips
ramp_a  = plug_a_t + 2 * plug_fit + plug_wall + 1.5;   // length of the 45 degree ramp under the USB-A clips
clip_h  = z_a + ramp_a + plug_len;         // sleeve height
flat    = xe - out_r;                      // half width of the flat part of the front plate
function row_w(w) = plug_n * (w + 2 * plug_fit) + (plug_n + 1) * plug_wall;   // width of a row of clips

assert(slot_open < ch_d, "Channel opening must be narrower than the channel");
assert(plug_grip < plug_a_w / 2 && plug_grip < plug_c_w / 2, "Grip too big");
assert(row_w(plug_a_w) <= 2 * flat, "USB-A clips do not fit on the flat front plate: fewer clips or a wider power bank");
assert(row_w(plug_c_w) <= 2 * flat, "USB-C clips do not fit on the flat front plate");
assert(ch_len <= py + fit + back_t - 2 * out_r, "Channels longer than the flat side wall");
assert(pb_r > 0 && pb_r <= pb_t / 2, "Corner radius does not fit");

module rrect(x0, x1, y0, y1, r) {
    offset(r = r) translate([x0 + r, y0 + r]) square([x1 - x0 - 2 * r, y1 - y0 - 2 * r]);
}

module cavity() { rrect(-pb_w / 2 - fit, pb_w / 2 + fit, -fit, pb_t + fit, pb_r + fit); }
module outer() rrect(-xe, xe, -fit - back_t, py, out_r);
module back_open() { translate([-(pb_w / 2 - back_lip), -fit - back_t - 5]) square([pb_w - 2 * back_lip, 5 + back_t + fit]); }

module layer2d() {
    difference() {
        outer();
        cavity(); back_open();
    }
}

// A row of plug clips in cross-section: x across the plate, y up from the plate surface (y = 0).
module plug_row2d(w, t) {
    cw = w + 2 * plug_fit; ct = t + 2 * plug_fit;
    L = row_w(w);
    difference() {
        rrect(-L / 2, L / 2, -1.5, ct + plug_wall, 2);
        for (i = [0 : plug_n - 1]) translate([-L / 2 + plug_wall + cw / 2 + i * (cw + plug_wall), 0]) {
            rrect(-cw / 2, cw / 2, 0, ct, min(ct / 2 - 0.1, 2.5));
            translate([-(cw / 2 - plug_grip), ct / 2]) square([cw - 2 * plug_grip, ct]);
        }
    }
}

module plug_pair(w, t, z, len) {
    translate([0, 0, z]) linear_extrude(height = len) translate([0, py]) plug_row2d(w, t);
}

// Comb of channels on each side wall: profile in (outwards, up), extruded across the thickness. Walls and channel
// openings slope up going outwards (a shear); the round part of each channel keeps its shape.
module comb() {
    k  = tan(comb_angle);
    u0 = ch_wall + ch_d / 2;   // channel centre, from the side wall
    u1 = ch_d + 2 * ch_wall;
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([xe, (pb_t + ch_len) / 2, z_f0]) rotate([90, 0, 0]) linear_extrude(height = ch_len)
            difference() {
                polygon([[-1, 0], [u1, k * (u1 + 1)], [u1, k * (u1 + 1) + wrap_h], [-1, wrap_h]]);
                for (i = [0 : threads - 1]) translate([u0, k * (u0 + 1) + hb + i * pitch]) {
                    hull() {   // teardrop: the top is a 45 degree point
                        circle(d = ch_d, $fn = 48);
                        translate([0, ch_d / 2 * sqrt(2)]) square(0.01, center = true);
                    }
                    L = u1 - u0 + 1;
                    polygon([[0, -slot_v / 2], [L, -slot_v / 2 + k * L], [L, slot_v / 2 + k * L], [0, slot_v / 2]]);
                }
            }
}

// USB-A clips: the underside is a 45 degree ramp from the plate, so no layer hangs in the air.
module clips_a() {
    intersection() {
        plug_pair(plug_a_w, plug_a_t, z_a, ramp_a + plug_len);
        translate([-100, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = 200)
            polygon([[py - 5, z_a], [py - 1.5, z_a], [py + 40, z_a + 41.5], [py + 40, clip_h + 1], [py - 5, clip_h + 1]]);
    }
}

module holder() {
    linear_extrude(height = clip_h) layer2d();
    plug_pair(plug_c_w, plug_c_t, 0, plug_len);
    clips_a();
    comb();
}

holder();
