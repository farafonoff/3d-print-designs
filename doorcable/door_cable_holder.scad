// Thin ethernet cable guide for the gap under a door (print in PETG, or TPU for a softer snap-in).
// A U-shaped strip standing on edge, lying flat on the floor: straight leg, elliptical bend, straight middle
// (goes through the gap under the door), bend, straight leg. The cable clips into a channel that
// opens towards the outside of the U (open_inside = true: towards the inside). The back is
// slightly rounded.
// The strip is gap_h - 0.5 tall and stands on the floor. A plate behind it, along the legs and the
// middle, holds 20 mm tape in a recess on its underside, so the tape does not add to the height.
//
// Parameters marked (measure) are worth checking against your door and cable.

$fn = 64;

// ---------- Door and cable ----------
gap_h       = 7;       // (measure) height of the gap under the door
strip_h     = gap_h - 0.5;   // strip height (6.5)
cable_d     = 5;       // (measure) cable thickness
channel_d   = cable_d + 0.2;   // channel diameter, for an easy fit

// ---------- Path (centre line of the channel) ----------
leg_a       = 40;      // straight leg A (mm)
leg_b       = 40;      // straight leg B (mm)
mid_len     = 10;      // straight middle between the bends (mm)
// Each bend is a quarter ellipse with two extents: along the legs (leg) and along the middle (mid, towards
// the other leg); equal values make a circle. Bend A joins leg A to the middle, bend B the middle to leg B.
// Bend extents, mid_len and min_width are measured wall to wall, between the faces of the strip that face
// the inside of the U (not along the centre line of the channel). Leg lengths are the straight lengths.
bend_a_leg    = 15;    // (measure)
bend_a_mid    = 20;    // (measure)
bend_b_leg    = 15;    // (measure)
bend_b_mid    = 27;    // (measure)
bend_steps    = 48;    // straight pieces per bend

// ---------- Profile ----------
open_inside = false;   // false: channel opens towards the outside of the U (easier to handle the cable); true: towards the inside
slot_open   = 4.6;     // width of the opening, a bit less than cable_d so the cable snaps in (raise it if the strip is stiff)
floor_t     = 0.9;     // wall under the channel (thick); the wall above it (the ceiling) is what is left of strip_h, 0.4 by default
lip_t       = 0.8;     // wall in front of the channel (opening side)
back_t      = 1.0;     // wall behind the channel
back_r      = 6;       // radius of the rounded back (larger = flatter)
edge_r      = 0.4;     // rounding of the strip edges in cross-section
tip_r       = 1.5;     // rounding of the corners at the two free leg ends in plan

// ---------- Tape base ----------
// The strip itself stands on the floor. The plates beside it have a recess on the underside for
// the tape, so the tape does not add to the height (it stands 0.1 mm proud and squashes down).
// The channel wall is too thin for a recess, and a plate on the opening side would block the
// cable, so the plate runs along the back of the strip, away from the opening.
tape_w      = 20;      // double-sided tape width
tape_t      = 1;       // tape thickness
plate_t     = 1.8;     // plate thickness (leaves plate_t - tape_t + 0.1 under the recess)
plate_legs  = true;    // plates along the legs
plate_r     = 3;       // corner radius of the plates in plan (the top edge is rounded too)
plate_inside = false;  // plates on the inside of the U (false: outside, the default); independent of open_inside
tape_ribs   = 2;      // ribs along the tape recess, so the plate rests on the bed when printed (no floating cantilever); cut the tape lengthwise into tape_ribs + 1 strips. 0 = one open recess
rib_w       = 1.2;     // rib width
plate_relief = 1.5;    // where the plate is on the opening side: width next to the strip lowered to the slot floor, so the cable can slide in (0 = none)
plate_mid   = true;    // plate under the middle section (the door stands on it, so keep it inside gap_h)

// ---------- Derived ----------
s_front = -(channel_d / 2 + lip_t);
s_back  =  channel_d / 2 + back_t;
plate_rel = plate_inside == open_inside ? plate_relief : 0;   // plate on the opening side: leave room for the cable
plate_tape0 = plate_rel > 0 ? -s_front + plate_rel : s_back;   // where the tape starts, from the channel centre
plate_x1_ = plate_tape0 + tape_w + 1.2;   // how far the plate reaches from the channel centre
wall_in = open_inside ? -s_front : s_back;   // distance from the channel centre to the strip face that faces the inside of the U
a_leg = bend_a_leg + wall_in;   // the same extents along the centre line of the channel
a_mid = bend_a_mid + wall_in;
b_leg = bend_b_leg + wall_in;
b_mid = bend_b_mid + wall_in;
sep     = mid_len + a_mid + b_mid;   // distance between the legs (channel centres)
width   = sep - 2 * wall_in;         // clear width between the legs, wall to wall
min_width = 0;   // minimum clear width between the legs; 0 = no check

assert(slot_open < channel_d, "Opening must be narrower than the channel");
chan_y = floor_t + channel_d / 2;   // height of the channel centre
assert(strip_h - floor_t - channel_d >= 0.399, "Ceiling over the channel too thin");
assert(strip_h < gap_h, "Strip does not fit the gap");
if (width < min_width) echo(str("WARNING: clear width between the legs is ", width, " mm, want at least ", min_width));
// plates inside the U must not meet
if (plate_inside && sep < 2 * (plate_x1_ + 1))
    echo(str("WARNING: the leg plates overlap inside the U (legs ", sep, " mm apart, plates reach ", plate_x1_, " mm each); lengthen mid_len or narrow tape_w"));

// sharpest radius of a quarter ellipse is at the end of the shorter semi-axis
function rmin(a, b) = min(a, b) * min(a, b) / max(a, b);
for (r = [rmin(a_leg, a_mid), rmin(b_leg, b_mid)])
    if (r < 4 * cable_d) echo(str("WARNING: tightest bend radius is ", r, " mm, ethernet cable wants >= ", 4 * cable_d));

// Cross-section: x across the strip (negative = opening side), y = height from the floor.
module body() {
    offset(r = edge_r, $fn = 24) offset(delta = -edge_r)
        intersection() {
            translate([s_front, 0]) square([s_back - s_front, strip_h]);
            translate([s_back - back_r, strip_h / 2]) circle(r = back_r, $fn = 180);
        }
}

module flip() { mirror([open_inside ? 0 : 1, 0]) children(); }

module cavity() {
    translate([0, chan_y]) circle(d = channel_d, $fn = 64);
    translate([s_front - 1, chan_y - slot_open / 2]) square([-s_front + 1, slot_open]);
}

module profile() {
    flip() difference() { body(); cavity(); }
}

// Plate beside the strip, on one side only. If that is the opening side, the plate next to the strip
// is kept below the slot floor (plate_relief wide) so the cable can still slide in.
// Plan corners rounded, top edge rounded, tape recess on the underside.
plate_x0 = s_back - 1.5;
plate_x1 = plate_x1_;
module plate(len) {
    e = 0.4;   // top edge radius
    module rr(inset = 0) offset(delta = -inset)
        offset(r = plate_r) offset(delta = -plate_r)
            translate([plate_x0, 0]) square([plate_x1 - plate_x0, len]);
    difference() {
        hull() {
            linear_extrude(height = plate_t - e) rr();
            for (a = [30, 60, 90])
                translate([0, 0, plate_t - e + e * sin(a) - 0.01])
                    linear_extrude(height = 0.01) rr(e * (1 - cos(a)));
        }
        // tape recess, split by ribs into tape_ribs + 1 grooves
        groove_w = (tape_w + 0.2 - tape_ribs * rib_w) / (tape_ribs + 1);
        for (k = [0 : tape_ribs])
            translate([plate_tape0 + k * (groove_w + rib_w), 1, -1]) cube([groove_w, len - 2, tape_t - 0.1 + 1]);
        if (plate_rel > 0)   // beside the opening the plate stays below the slot floor
            translate([plate_x0 - 1, -1, chan_y - slot_open / 2 - 0.05]) cube([plate_tape0 - plate_x0 + 1, len + 2, strip_h]);
    }
}

// Straight piece from the origin along +y; tip0/tip1 round the plan corners at a free end.
module straight(len, with_plate = false, tip0 = false, tip1 = false) {
    y0 = tip0 ? 0 : -10;
    y1 = tip1 ? len : len + 10;
    difference() {
        union() {
            intersection() {
                along(0, len) flip() body();
                translate([0, 0, -1]) linear_extrude(height = strip_h + 2)
                    offset(r = tip_r) offset(delta = -tip_r) translate([-4, y0]) square([8, y1 - y0]);
            }
            if (with_plate) mirror([plate_inside ? 1 : 0, 0]) plate(len);
        }
        along(-1, len + 1) flip() cavity();
    }
}

// Left bend from the origin, heading +y: `ahead` is its extent along the start heading, `side` towards
// the left. A quarter ellipse centred at (-side, 0), swept as
// short straight pieces (each a little longer than the chord so the outside has no cracks).
module along(l0, l1) rotate([90, 0, 0]) translate([0, 0, -l1]) linear_extrude(height = l1 - l0) children();

module bend(bend_along, bend_across) {   // along = ahead, across = side
    function pt(t) = [-bend_across + bend_across * cos(t), bend_along * sin(t)];
    module pieces(ext, cut) {
        for (i = [0 : bend_steps - 1]) {
            p0 = pt(90 * i / bend_steps);
            d  = pt(90 * (i + 1) / bend_steps) - p0;
            translate([p0[0], p0[1], 0]) rotate(atan2(d[1], d[0]) - 90)
                along(-ext, norm(d) + ext) flip() if (cut) cavity(); else body();
        }
    }
    difference() {
        pieces(0.15, false);
        pieces(0.3, true);
    }
}

module holder() {
    straight(leg_a, plate_legs, tip0 = true);
    translate([0, leg_a, 0]) bend(a_leg, a_mid);
    translate([-a_mid, leg_a + a_leg, 0]) rotate(90) {
        straight(mid_len, plate_mid);
        translate([0, mid_len, 0]) bend(b_mid, b_leg);
        translate([-b_leg, mid_len + b_mid, 0]) rotate(90) straight(leg_b, plate_legs, tip1 = true);
    }
}

holder();
