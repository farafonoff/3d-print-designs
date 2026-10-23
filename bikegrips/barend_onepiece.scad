// One-piece version (fallback, see barend.scad for the two-piece expanding plug).
// Bar-end plug for the lock-on grip: an expanding plug that goes into the open end of the
// handlebar, a wide head that matches the grip, and an M6 countersunk bolt + nut that spread
// the slit plug against the bar wall.
// Remade from Barend.stl (Thingiverse), section measured from the file, with a 33 mm head
// to match the fat grip. Values marked [STL] come from that file.
//
//   head (thick, wide)   cone seat for a countersunk screw (11.6 mm at the face, narrowing to the shaft, 90 deg), then the straight 6 mm hole
//   plug (thin, long)    tapered M6 nut pocket in the tip, slit: tightening the bolt pulls the nut
//                        into the taper and spreads the plug against the tube
//
// Printed head down (outer face on the bed, plug pointing up), so neither the counterbore nor the
// nut pocket needs support. Assembly: bolt through the head, nut loose in the plug tip, then
// push the plug into the tube and tighten. Axis along Z.

$fn = 96;

// ---------- Head ----------
head_d       = 33;     // matches the grip ends (body_d in lockon_grip.scad); the original head was 22.4
head_h       = 10;     // [STL] head height
head_chamfer = 2;      // [STL] 45 deg chamfer on the outer edge of the free face

// ---------- Plug (goes into the bar) ----------
plug_len     = 16;     // [STL] length of the plug
plug_root_d  = 17.6;   // [STL] diameter where the plug leaves the head
plug_d       = 18.6;   // [STL] full diameter (the bar bore is about 18)
plug_d_at    = 6.2;    // [STL] distance from the head where the full diameter is reached
tip_d        = 15.5;   // [STL] diameter at the free end
tip_len      = 4.6;    // [STL] length of the lead-in bevel at the tip
tip_round    = 2.0;    // [STL] part of the bevel that starts rounded (full diameter ends here)
slit_w       = 0.5;    // [STL] slit across the plug so it can spread
slit_len     = plug_len;   // slit depth from the tip (the head stays whole)

// ---------- M6 bolt and nut ----------
bolt_clear   = 0.2;    // print clearance added to the M6 sizes (printed holes run small; raise if the bolt is tight)
bolt_d       = 6 + bolt_clear;   // M6 shank
head_recess_d = 11.6;  // countersunk M6 head diameter: the cone starts at the outer face with exactly this
head_recess_h = 0.1;   // short cylinder above the cone, so the head sinks completely (flush or 0.1 mm below)
nut_af       = 10;     // M6 nut across flats (ISO 4032 / DIN 934)
nut_ac       = nut_af / cos(30);   // M6 nut across corners (11.55)
wedge_len    = 8;      // depth of the tapered nut pocket from the plug tip
wedge_open   = nut_ac + 1.4;   // pocket across corners at the tip: the nut goes in easily
wedge_jam    = nut_ac - 0.5;   // pocket across corners at the bottom: smaller than the nut, so
                               // tightening the bolt wedges the nut in and spreads the slit plug
                               // (make the taper steeper for more spread, shallower for less)

top_z = head_h + plug_len;

module outer() {
    rotate_extrude()
        polygon([
            [0, 0],
            [head_d / 2 - head_chamfer, 0],
            [head_d / 2, head_chamfer],
            [head_d / 2, head_h],
            [plug_root_d / 2, head_h],
            [plug_d / 2, head_h + plug_d_at],
            [plug_d / 2, top_z - tip_len - tip_round / 2],
            [plug_d / 2 - 0.4, top_z - tip_len],
            [tip_d / 2, top_z],
            [0, top_z]]);
}

module bore() {
    // straight M6 hole through the head and the plug
    translate([0, 0, -1]) cylinder(d = bolt_d, h = top_z + 2);
    // head recess opening to the outer face: a cone (90 deg) narrowing into the bolt hole,
    // the seat for a countersunk screw; head_recess_h of straight wall keeps the head sunk
    translate([0, 0, -0.01])
        cylinder(d = head_recess_d, h = head_recess_h + 0.01);
    translate([0, 0, head_recess_h])
        cylinder(d1 = head_recess_d, d2 = bolt_d, h = (head_recess_d - bolt_d) / 2);
    // tapered nut pocket in the plug tip: wide at the tip, narrowing towards the head
    translate([0, 0, top_z - wedge_len])
        cylinder(d1 = wedge_jam, d2 = wedge_open, h = wedge_len + 0.01, $fn = 6);
}

module barend() {
    difference() {
        outer();
        bore();
        // slit across the plug from the tip
        translate([-plug_d, -slit_w / 2, top_z - slit_len])
            cube([2 * plug_d, slit_w, slit_len + 1]);
    }
}

barend();
