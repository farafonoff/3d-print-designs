// Lock-on bicycle grip, sleeve only (print in TPU).
// Reuses the metal lock rings from the original grip: 22.2 mm bar bore, a ring
// seat with two straight-sided lips at each end, deep small hex pockets between
// them, and engraved Claude / OpenAI logos on smooth pads.
// Parameters marked [MEASURE] still need checking against the real part.
//
// Print standing up (grip axis along Z). test_grip.scad prints just one end.

$fn = 96;

// ---------- Handlebar ----------
bar_d        = 22.2;   // standard MTB bar
fit_clear    = 0;      // 0 = exactly 22.2. Negative = tighter (TPU stretches); positive = looser

// ---------- Grip body ----------
grip_len     = 130;    // [MEASURE] overall length of old rubber
body_d       = 33;     // outer diameter of the pattern (top of the scales)
wall_min     = 2.4;    // minimum rubber wall (measured at the bottom of the grooves)

// ---------- Clamp seats (where the metal rings sit) ----------
ring_seat_len = 8;     // = lip depth, so the pattern starts exactly where the lips end
ring_seat_d   = 25.5;    // [MEASURE] outer diameter of the seat = inner diameter of
                       // the metal ring. Make it ~0.2 mm bigger than the ring bore.
ring_groove_d = 0.6;   // small retaining lip depth at the seat end
inboard_ring  = true;  // ring at the inner end (towards stem/brake lever)
outboard_ring = true;  // ring at the bar-end (original has rings both sides)

// ---------- Lips (from photo of original) ----------
// At each ring end the seat wall is cut back by lip_h with two rectangular
// cuts, one on each side, leaving two opposite lips with straight, parallel sides.
lip_h         = 8;     // depth of the lips (measured on original)
lip_w         = 15;    // distance between the two cutting planes (= lip width), measured on original
lip_angle     = 60;    // [MEASURE] direction of the first lip's centre; the second is opposite

// ---------- Bar end ----------
closed_end    = false; // true = domed closed end (no bar plug needed)
end_cap_wall  = 3;

// ---------- Hex "lizard skin" pattern (hex pockets, raised ridges) ----------
hex_r        = 1.5;    // circumradius of one hex cell (mm); ~2.6 mm across flats
ridge_w      = 0.8;    // width of the ridge between pockets at the surface
pat_depth    = 1.2;    // pocket depth
pocket_floor = 0.75;   // pocket floor size relative to its opening (1 = straight walls)

// ---------- Logos (engraved into a smooth round pad) ----------
// Marks are SVGs in logos/ (simple-icons, 24x24). Set a slot to "" to skip it.
logo_a        = "logos/claude.svg";
logo_b        = "logos/openai.svg";
logo_a_z      = grip_len / 2 - 18;  // position along the grip (mm from the inboard end)
logo_b_z      = grip_len / 2 + 18;
logo_angle    = 90;    // which side of the grip the logos face (degrees around the bar)
logo_rot      = 90;    // rotation of the logo within its pad (90 = upright for a rider)
logo_size     = 14;    // logo width (mm)
pad_d         = 19;    // smooth pad diameter (hex pockets are filled in here)
logo_depth    = 0.8;   // engraving depth (stay under pat_depth + wall)

// ---------- Derived ----------
bore_d    = bar_d + fit_clear;
knurl_len = grip_len - (inboard_ring ? ring_seat_len : 0)
                     - (outboard_ring ? ring_seat_len : 0);

function max2(a, b) = a > b ? a : b;
assert(body_d/2 - pat_depth - bore_d/2 >= wall_min, "Wall under the grooves too thin");
assert(ring_seat_d/2 - bore_d/2 >= 1.5, "Ring seat wall too thin");

// Hex pockets sunk into the body, staggered row by row.
// Cells point along Z (vertex up), pitch = sqrt(3)*r around, 1.5*r along.
module knurled(len) {
    r_out  = body_d / 2;
    r_core = r_out - pat_depth;
    pitch  = sqrt(3) * hex_r;
    n      = round(PI * body_d / pitch);
    rows   = ceil(len / (1.5 * hex_r)) + 1;
    h      = pat_depth + 0.5;                       // pocket tool runs past the surface
    rt     = hex_r - ridge_w / 2;                   // opening radius at the surface
    rb     = rt * pocket_floor;                     // floor radius
    s      = 1 + (rt / rb - 1) * h / pat_depth;     // so the opening is rt at r_out
    difference() {
        cylinder(r = r_out, h = len);
        for (k = [0 : rows - 1])
            for (j = [0 : n - 1])
                rotate([0, 0, (j + (k % 2) * 0.5) * 360 / n])
                    translate([r_core, 0, hex_r + k * 1.5 * hex_r])   // first row starts with a whole cell
                        rotate([0, 90, 0])
                            linear_extrude(height = h, scale = s)
                                circle(r = rb, $fn = 6);
    }
}

module ring_seat() {
    // short cylinder with a small raised lip on the outer edge to stop the ring sliding off
    cylinder(d = ring_seat_d, h = ring_seat_len);
    translate([0, 0, ring_seat_len - 1.2])
        cylinder(d = ring_seat_d + 2 * ring_groove_d, h = 1.2);
}

module grip_outer() {
    z0 = inboard_ring ? ring_seat_len : 0;

    if (inboard_ring) {
        ring_seat();
    }

    translate([0, 0, z0 - 0.01])
        knurled(knurl_len + 0.02);

    if (outboard_ring)
        translate([0, 0, grip_len]) mirror([0, 0, 1]) ring_seat();

    // domed closed end
    if (closed_end)
        translate([0, 0, grip_len - 0.01])
            intersection() {
                cylinder(d = outboard_ring ? ring_seat_d : body_d, h = end_cap_wall);
                scale([1, 1, 0.3]) sphere(d = outboard_ring ? ring_seat_d : body_d);
            }
}

// 2D footprint of a logo slot, centred and sized
module logo2d(file) {
    resize([logo_size, 0], auto = true)
        import(file, center = true);
}

// Extrude a 2D shape radially outward from the axis, onto the +X side,
// then place it at (angle, z). 2D x -> around the bar, 2D y -> along it.
module radial(angle, z, h) {
    rotate([0, 0, angle]) translate([0, 0, z])
        rotate([90, 0, 90]) linear_extrude(height = h) children();
}

module logo_pads() {
    for (p = [[logo_a, logo_a_z], [logo_b, logo_b_z]])
        if (p[0] != "")
            intersection() {
                cylinder(d = body_d, h = grip_len);
                radial(logo_angle, p[1], body_d / 2 + 1) circle(d = pad_d);
            }
}

module logo_engravings() {
    for (p = [[logo_a, logo_a_z], [logo_b, logo_b_z]])
        if (p[0] != "")
            difference() {
                radial(logo_angle, p[1], body_d / 2 + 2) rotate(logo_rot) logo2d(p[0]);
                translate([0, 0, -1]) cylinder(d = body_d - 2 * logo_depth, h = grip_len + 2);
            }
}

module grip() {
    difference() {
        union() { grip_outer(); logo_pads(); }
        logo_engravings();
        // bar bore
        translate([0, 0, -0.1])
            cylinder(d = bore_d, h = grip_len - (closed_end ? end_cap_wall : 0) + 0.1);
        // cut back the seat between the lips
        if (inboard_ring)  lip_gaps();
        if (outboard_ring) translate([0, 0, grip_len]) mirror([0, 0, 1]) lip_gaps();
    }
}

// Two rectangular cuts, one on each side of the lips, from the ring end (z=0) inwards
module lip_gaps() {
    L = ring_seat_d + 2 * ring_groove_d + 2;
    rotate([0, 0, lip_angle - 90])          // local +Y = lip direction
        for (m = [0, 1])
            mirror([m, 0, 0])
                translate([lip_w / 2, -L / 2, -0.01])
                    cube([L, L, lip_h + 0.01]);
}

grip();
