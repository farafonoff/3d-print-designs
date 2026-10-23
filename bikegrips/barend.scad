// Expanding bar-end plug for the lock-on grip, two pieces:
//   sleeve  the wide head (33 mm, matches the grip) + a plug cut by crossed slits (four petals) with a conical bore
//   wedge   a cone with the M6 nut in a closed cavity (slid in from the side, back wall behind it);
//           fins slide in the slits so it cannot spin
// An M6 countersunk screw goes in through the head, through the wedge and into the nut.
// Tightening it pulls the wedge into the sleeve and spreads the plug against the tube wall.
// Remade from Barend.stl (Thingiverse); head and plug sizes follow that file, the wedge is new.
// Values marked [STL] come from that file. barend_onepiece.scad is the simpler fallback.
//
// layout = "print"      both parts side by side, ready to print (default)
//          "sleeve"     the sleeve alone   } to export each part as its own STL:
//          "wedge"      the wedge alone    }   openscad -D 'layout="wedge"' -o wedge.stl barend.scad
//          "assembled"  wedge pulled into the sleeve, to check the fit
// Print the sleeve head down and the wedge on its back wall (big face), so nothing needs support. PETG.
// Assembly: slide the nut into the wedge from the side, push the wedge into the plug tip with the
// fins in the slits, then screw in from the head. Unscrewing drives the nut against the back wall
// and pushes the wedge out of the cone.
// Screw: M6 x 30 countersunk. The sleeve is 26 mm long, so the tip passes through the nut and
// sticks out ~4 mm; with the wedge pulled in all the way it ends up ~13 mm past the nut, fine.

$fn = 96;
layout = "print";
section = false;   // true: cut away half to look at the inside

// ---------- Head ----------
head_d       = 33;     // matches the grip ends (body_d in lockon_grip.scad); the original head was 22.4
head_h       = 5;      // head height (half of the original 10, the saved length goes to the plug): the screw seat is 2.9 mm deep, leaving 2.1 mm under it
head_chamfer = 2;      // [STL] 45 deg chamfer on the outer edge of the free face

// ---------- Plug (goes into the bar) ----------
plug_len     = 21;     // length of the plug (the original 16, plus the 5 mm saved on the head: longer petals flex more)
plug_root_d  = 17.6;   // [STL] diameter where the plug leaves the head
plug_d       = 18.6;   // [STL] full diameter (the bar bore is about 18)
plug_d_at    = 6.2;    // [STL] distance from the head where the full diameter is reached
tip_d        = 17.4;   // diameter at the free end (kept wide so the bore leaves a sound wall)
tip_len      = 3;      // length of the lead-in bevel at the tip
slit_planes  = 2;      // number of cutting planes through the axis: 2 = crossed slits, four petals; 1 = one slit, two halves
slit_w       = 2;      // wide enough for the wedge fin, closes up when the plug is squeezed into the tube
slit_len     = plug_len;   // slit depth from the tip (the head stays whole)

// ---------- M6 screw and nut ----------
bolt_clear   = 0.2;    // print clearance added to the M6 sizes (printed holes run small)
bolt_d       = 6 + bolt_clear;
screw_head_d = 11.6;   // countersunk M6 head: a 90 deg cone from the outer face, narrowing to the shaft
screw_sink   = 0.1;    // straight wall above the cone so the head sinks completely
nut_af       = 10;     // M6 nut across flats
nut_h        = 5.2;    // M6 nut thickness
nut_ac       = (nut_af + bolt_clear) / cos(30);   // pocket across corners (11.8)

// ---------- Wedge ----------
wedge_angle  = 6;      // half-angle of the cone (deg): steeper = more spread per mm of travel but may bind
wedge_gap    = 0.2;    // radial gap between wedge and bore at rest
wedge_len    = 10;     // length of the wedge cone
back_wall    = 2;      // wall behind the nut at the big end: unscrewing pushes the nut against it and drives the wedge out
slot_dir     = 45;     // direction the nut is slid in from the side (deg), between two fins
wedge_travel = 9;      // how far the wedge can be pulled in (more travel = more spread; about 1.4 mm is lost closing the gap)
bore_depth   = wedge_len + wedge_travel;   // depth of the conical bore from the plug tip
bore_tip_d   = 15.2;   // bore diameter at the plug tip (leaves (tip_d - this)/2 = 1.1 mm wall)
fin_w        = 1.4;    // wedge fin thickness (must be < slit_w)

top_z    = head_h + plug_len;
bore_bot = bore_tip_d - 2 * bore_depth * tan(wedge_angle);   // bore diameter at its bottom
wedge_top = bore_tip_d - 2 * wedge_gap;                      // wedge diameter at its big end
wedge_bot = wedge_top - 2 * wedge_len * tan(wedge_angle);

assert(head_h - screw_sink - (screw_head_d - bolt_d) / 2 >= 1.5, "Head too thin under the screw seat");
assert(fin_w < slit_w, "Fin does not fit in the slit");
assert(bore_bot > bolt_d + 2, "Bore bottom too narrow");
assert(wedge_top / 2 - (back_wall + nut_h + 0.3) * tan(wedge_angle) >= nut_ac / 2 + 0.6,
       "Wedge wall too thin behind the nut");
assert(wedge_len - back_wall - (nut_h + 0.3) >= 1.5, "Wedge front plate too thin");

module outer() {
    rotate_extrude()
        polygon([
            [0, 0],
            [head_d / 2 - head_chamfer, 0],
            [head_d / 2, head_chamfer],
            [head_d / 2, head_h],
            [plug_root_d / 2, head_h],
            [plug_d / 2, head_h + plug_d_at],
            [plug_d / 2, top_z - tip_len],
            [tip_d / 2, top_z],
            [0, top_z]]);
}

module sleeve() {
    difference() {
        outer();
        // straight M6 hole through the head and plug
        translate([0, 0, -1]) cylinder(d = bolt_d, h = top_z + 2);
        // cone seat for the countersunk screw, starting at the outer face
        translate([0, 0, -0.01]) cylinder(d = screw_head_d, h = screw_sink + 0.01);
        translate([0, 0, screw_sink])
            cylinder(d1 = screw_head_d, d2 = bolt_d, h = (screw_head_d - bolt_d) / 2);
        // conical bore for the wedge, wide at the plug tip
        translate([0, 0, top_z - bore_depth])
            cylinder(d1 = bore_bot, d2 = bore_tip_d, h = bore_depth + 0.01);
        // slits across the plug from the tip, one per cutting plane
        for (i = [0 : slit_planes - 1])
            rotate([0, 0, i * 180 / slit_planes])
                translate([-plug_d, -slit_w / 2, top_z - slit_len])
                    cube([2 * plug_d, slit_w, slit_len + 1]);
    }
}

// Local z = 0 is the big end (the nut face); the cone narrows towards +z.
module wedge() {
    difference() {
        union() {
            cylinder(d1 = wedge_top, d2 = wedge_bot, h = wedge_len);
            // fins running in the slits, along the whole cone
            for (i = [0 : slit_planes - 1])
                rotate([0, 0, i * 180 / slit_planes])
                    intersection() {
                        translate([-(plug_d / 2 - 0.5), -fin_w / 2, 0]) cube([plug_d - 1, fin_w, wedge_len]);
                        cylinder(d1 = wedge_top + 2, d2 = wedge_bot + 2, h = wedge_len);
                    }
        }
        translate([0, 0, -1]) cylinder(d = bolt_d, h = wedge_len + 2);
        // closed nut cavity between the back wall and the front plate; the nut is slid in from
        // the side (hull of two hexes), its flats against the slot sides so it cannot turn
        translate([0, 0, back_wall])
            linear_extrude(height = nut_h + 0.3)
                rotate(slot_dir)
                    hull() {
                        circle(d = nut_ac, $fn = 6);
                        translate([wedge_top, 0]) circle(d = nut_ac, $fn = 6);
                    }
    }
}

module build() {
    if (layout == "assembled") {
        sleeve();
        translate([0, 0, top_z]) mirror([0, 0, 1]) wedge();
    } else if (layout == "sleeve") {
        sleeve();
    } else if (layout == "wedge") {
        wedge();
    } else {
        sleeve();
        translate([head_d / 2 + wedge_top / 2 + 6, 0, 0]) wedge();
    }
}

difference() {
    build();
    if (section) translate([-100, -100, -1]) cube([100, 200, 100]);   // cut away the x<0 half
}
