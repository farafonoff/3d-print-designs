// Thin ethernet cable guide for the gap under a door, mk2: an open-top channel on a flat base.
// A U-shaped path lying flat on the floor: straight leg, elliptical bend, straight middle (goes under
// the door), bend, straight leg. The cable is pressed into the channel from above and held by the
// narrower opening. The channel has thick walls and a flat lip on the outer side of the U; channel and
// lip together are tape_w wide, with a flat bottom: stick the double-sided tape straight onto it.
// The tape adds tape_t under the door, so the part is gap_h - tape_t - clearance tall.
// Print flat, base down: no supports.
//
// Bend extents, mid_len and min_width are measured wall to wall, between the faces of the channel walls
// that face the inside of the U (not along the centre line of the channel). Leg lengths are the
// straight lengths.

$fn = 64;

// ---------- Door and cable ----------
gap_h       = 7;       // (measure) height of the gap under the door
cable_d     = 5;       // (measure) cable thickness
channel_d   = cable_d + 0.2;   // channel diameter, for an easy fit

// ---------- Path (centre line of the channel) ----------
leg_a       = 40;      // straight leg A (mm)
leg_b       = 40;      // straight leg B (mm)
mid_len     = 10;      // straight middle between the bends (mm)
// Each bend is a quarter ellipse with two extents: along the legs (leg) and along the middle (mid, towards
// the other leg); equal values make a circle. Bend A joins leg A to the middle, bend B the middle to leg B.
bend_a_leg    = 15;    // (measure)
bend_a_mid    = 20;    // (measure)
bend_b_leg    = 15;    // (measure)
bend_b_mid    = 27;    // (measure)
bend_steps    = 120;   // straight pieces per bend
min_width     = 0;     // minimum clear width between the legs, wall to wall; 0 = no check

// ---------- Channel ----------
floor_t     = 0.8;     // base thickness under the cable (limited by gap_h - tape_t - cable_d)
lip_thick   = 2;       // thickness of the flat lip beside the channel (free: the lip is not under the cable)
wall_t      = 2;       // channel wall thickness (at the channel's widest)
slot_open   = 4.6;     // width of the opening at the top, a bit less than cable_d so the cable snaps in (raise it if the strip is stiff)
edge_r      = 0.3;     // rounding of the outline in cross-section
tip_r       = 3;       // corner radius of the base at the two free leg ends, in plan

// ---------- Tape ----------
tape_w      = 20;      // double-sided tape width = width of channel + lip
tape_t      = 1;       // tape thickness
clearance   = 0.2;     // spare height in the gap, above the tape and the part

// ---------- Derived ----------
body_h  = gap_h - tape_t - clearance;   // height of the part
chan_y  = floor_t + channel_d / 2;      // height of the channel centre
wall_in = channel_d / 2 + wall_t;       // channel centre line to the wall face (inner face towards the U, outer face away from it)
a_leg = bend_a_leg + wall_in;           // bend extents along the centre line of the channel
a_mid = bend_a_mid + wall_in;
b_leg = bend_b_leg + wall_in;
b_mid = bend_b_mid + wall_in;
sep   = mid_len + a_mid + b_mid;        // distance between the legs (channel centres)
width = sep - 2 * wall_in;              // clear width between the legs, wall to wall

assert(floor_t + cable_d + tape_t <= gap_h, "Floor + cable + tape does not fit the gap");
assert(body_h > chan_y, "Walls must rise above the channel centre to hold the cable");
assert(lip_thick < body_h, "Lip taller than the part");
assert(tape_w > 2 * wall_in, "Base narrower than the channel");
if (width < min_width) echo(str("WARNING: clear width between the legs is ", width, " mm, want at least ", min_width));
// sharpest radius of a quarter ellipse is at the end of the shorter semi-axis
function rmin(a, b) = min(a, b) * min(a, b) / max(a, b);
for (r = [rmin(a_leg, a_mid), rmin(b_leg, b_mid)])
    if (r < 4 * cable_d) echo(str("WARNING: tightest bend radius is ", r, " mm, ethernet cable wants >= ", 4 * cable_d));

// Cross-section: x across the path (negative = inside of the U), y = height from the floor.
module body() {
    er = min(edge_r, lip_thick / 2 - 0.05);   // the rounding must leave the lip standing
    offset(r = er, $fn = 24) offset(delta = -er) union() {
        translate([-wall_in, 0]) square([2 * wall_in, body_h]);                   // channel walls
        translate([-wall_in, 0]) square([tape_w, lip_thick]);                         // flat base with the lip on the outer side
    }
}

module cavity() {
    translate([0, chan_y]) circle(d = channel_d, $fn = 64);
    translate([-slot_open / 2, chan_y]) square([slot_open, body_h - chan_y + 1]);   // opening up to the top face
}

module along(l0, l1) rotate([90, 0, 0]) translate([0, 0, -l1]) linear_extrude(height = l1 - l0) children();

// Straight piece from the origin along +y; tip0/tip1 round the plan corners at a free end.
module straight(len, tip0 = false, tip1 = false) {
    y0 = tip0 ? 0 : -10;
    y1 = tip1 ? len : len + 10;
    difference() {
        intersection() {
            along(0, len) body();
            translate([0, 0, -1]) linear_extrude(height = body_h + 2)
                offset(r = tip_r) offset(delta = -tip_r) translate([-wall_in, y0]) square([tape_w, y1 - y0]);
        }
        along(-1, len + 1) cavity();
    }
}

// Left bend from the origin, heading +y: `bend_along` is its extent along the start heading, `bend_across`
// towards the left. A quarter ellipse centred at (-bend_across, 0), swept as short straight pieces
// (each a little longer than the chord so the outer edge of the lip has no cracks).
module bend(bend_along, bend_across) {
    function pt(t) = [-bend_across + bend_across * cos(t), bend_along * sin(t)];
    module pieces(ext, cut) {
        for (i = [0 : bend_steps - 1]) {
            p0 = pt(90 * i / bend_steps);
            d  = pt(90 * (i + 1) / bend_steps) - p0;
            translate([p0[0], p0[1], 0]) rotate(atan2(d[1], d[0]) - 90)
                along(-ext, norm(d) + ext) if (cut) cavity(); else body();
        }
    }
    difference() {
        pieces(0.5, false);
        pieces(0.6, true);
    }
}

module holder() {
    straight(leg_a, tip0 = true);
    translate([0, leg_a, 0]) bend(a_leg, a_mid);
    translate([-a_mid, leg_a + a_leg, 0]) rotate(90) {
        straight(mid_len);
        translate([0, mid_len, 0]) bend(b_mid, b_leg);
        translate([-b_leg, mid_len + b_mid, 0]) rotate(90) straight(leg_b, tip1 = true);
    }
}

holder();
