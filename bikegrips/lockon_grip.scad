// Lock-on bicycle grip, sleeve only (print in TPU).
// Reuses the metal lock rings from the original grip: 22.2 mm bar bore, a ring
// seat with two straight-sided lips at each end, a barrel-shaped body (thicker in
// the middle) covered in deep hex pockets, and Claude / OpenAI logos engraved into
// the pattern with a solid border.
// Parameters marked [MEASURE] still need checking against the real part.
//
// Print standing up (grip axis along Z). test_grip.scad prints just one end.

$fn = 96;

// ---------- Handlebar ----------
bar_d        = 22.2;   // standard MTB bar
fit_clear    = 0;      // bore = bar_d + fit_clear = 22.2. Original measured 22.2-22.3; printed holes run ~0.1-0.2 small and TPU stretches, so 0 should be snug. Tune by +-0.1 after the test print.

// ---------- Grip body ----------
grip_len     = 130;    // [MEASURE] overall length of old rubber
body_d       = 33;     // outer diameter at the ends of the pattern, top of the ridges (fat grip; the original measured 29)
bulge        = 0.5;    // extra radius at the middle of the grip: barrel shape, 0 = straight cylinder
                       // (0.5 -> 34 mm in the middle, smooth sine profile, ends stay at body_d)
ring_od      = 33;     // outer diameter of the metal ring (caliper): the rubber flares out to meet it
flare_len    = 3;      // length of the angled connection from the body (body_d) out to ring_od (mm), 0 = square shoulder
wall_min     = 2.0;    // minimum rubber wall (measured at the bottom of the pockets)

// ---------- Clamp seats (where the metal rings sit) ----------
ring_seat_len = 8;     // lip depth = width of the metal ring (caliper); the pattern starts exactly where the lips end
ring_seat_d   = 26.3;  // outer diameter of the lips (caliper)
ring_groove_d = 0;     // optional collar at the lip root (0 = none: the ring sits flush against the body; 0.6 left a crack)
inboard_ring  = true;  // ring at the inner end (towards stem/brake lever)
outboard_ring = true;  // ring at the bar-end (original has rings both sides)

// ---------- Lips (caliper measurements of the original) ----------
// At each ring end the seat wall is cut back by lip_h with two rectangular
// cuts, one on each side, leaving two opposite lips with straight, parallel sides.
lip_h         = ring_seat_len;   // depth of the lips = seat length
lip_w         = 16.3;  // distance between the two cutting planes (= lip width)
lip_angle     = 60;    // [MEASURE] direction of the first lip's centre; the second is opposite

// ---------- Bar end ----------
closed_end    = false; // true = domed closed end (no bar plug needed)
end_cap_wall  = 3;

// ---------- Hex "lizard skin" pattern (hex pockets, raised ridges) ----------
hex_r        = 2.25;   // circumradius of one hex cell (mm); ~3.9 mm across flats
ridge_w      = 0.88;   // width of the ridge between pockets at the surface
pat_depth    = 1.2;    // pocket depth at the ends of the pattern; the pocket floors lie on a straight cylinder
//                        (core_d), so the pockets get deeper where the barrel swells
pocket_floor = 0.85;   // keeps the wall slope ~0.3 mm over the depth, as with the smaller cells
//                        (floor size relative to the opening; 1 = straight walls)

// ---------- Logos (engraved into the hex pattern, with a solid border) ----------
// Marks are SVGs in logos/ (simple-icons, 24x24). Set a slot to "" to skip it.
logo_a        = "logos/claude.svg";
logo_b        = "logos/openai.svg";
logo_a_z      = grip_len / 2;  // position along the grip (mm from the inboard end)
logo_b_z      = grip_len / 2;
logo_a_angle  = 90;    // which side of the grip logo A faces (degrees around the bar)
logo_b_angle  = logo_a_angle + 180;   // logo B on the opposite side
logo_a_rot    = 90;    // rotation of the logo around its centre (90 = upright for a rider)
logo_b_rot    = logo_a_rot + 180;     // +180 so both read the same way up around the bike
logo_size     = 14;    // logo width (mm)
logo_depth    = 0.8 * pat_depth;   // engraving depth below the ridge tops (80% of the pocket depth)
logo_border   = 1.2;   // width of the solid frame around the logo lines (fills the hex pockets)

// ---------- Derived ----------
core_d    = body_d - 2 * pat_depth;   // diameter of the pocket floors: the fixed core under the pattern
bore_d    = bar_d + fit_clear;
knurl_len = grip_len - (inboard_ring ? ring_seat_len : 0)
                     - (outboard_ring ? ring_seat_len : 0);

knurl_z0  = inboard_ring ? ring_seat_len : 0;
knurl_z1  = grip_len - (outboard_ring ? ring_seat_len : 0);

function max2(a, b) = a > b ? a : b;

// Outer radius of the pattern at global height z (barrel profile, clamped to the pattern span)
// plus a linear flare out to ring_od/2 at each ring end (only where a ring is fitted)
function flare(d) = flare_len > 0 && ring_od > body_d ? max(0, 1 - d / flare_len) * max(0, ring_od / 2 - body_d / 2) : 0;
function body_r(z) = body_d / 2 + bulge * sin(180 * min(max(z - knurl_z0, 0), knurl_len) / knurl_len)
    + (inboard_ring  ? flare(z - knurl_z0) : 0)
    + (outboard_ring ? flare(knurl_z1 - z) : 0);

// Solid of revolution with the barrel profile over the pattern span, offset radially by off (mm)
module envelope(off = 0) {
    steps = 240;
    rotate_extrude($fn = 96)
        polygon(concat(
            [[0, knurl_z0 - 0.01]],
            [for (i = [0 : steps]) let (z = knurl_z0 + knurl_len * i / steps)
                [body_r(z) + off, z + (i == 0 ? -0.01 : i == steps ? 0.01 : 0)]],
            [[0, knurl_z1 + 0.01]]));
}
assert(body_d/2 - pat_depth - bore_d/2 >= wall_min, "Wall under the grooves too thin");
assert(ring_seat_d/2 - bore_d/2 >= 1.5, "Ring seat wall too thin");

// Hex pockets sunk into the body, staggered row by row, following the barrel profile.
// Cells point along Z (vertex up), pitch = sqrt(3)*r around, 1.5*r along.
module knurled() {
    pitch  = sqrt(3) * hex_r;
    n      = round(PI * body_d / pitch);          // cells per ring (same at every height)
    fl     = ring_od > body_d ? flare_len : 0;      // no flare when the body is already as wide as the ring
    f0     = inboard_ring  ? fl : 0;         // the flare stays solid, the pattern starts after it
    f1     = outboard_ring ? fl : 0;
    rows   = ceil((knurl_len - f0 - f1) / (1.5 * hex_r)) + 1;
    rt     = hex_r - ridge_w / 2;                   // opening radius at the surface
    difference() {
        envelope();
        for (k = [0 : rows - 1]) {
            zc = knurl_z0 + f0 + hex_r + k * 1.5 * hex_r;   // first row starts with a whole cell
            d  = body_r(zc) - core_d / 2;                   // pocket depth here
            h  = d + 0.5;                                   // pocket tool runs past the surface
            rb = rt * (1 - (1 - pocket_floor) * d / pat_depth);   // floor radius: wall slope stays the same at any depth
            s  = 1 + (rt / rb - 1) * h / d;                 // so the opening is rt at the surface
            if (zc + hex_r <= knurl_z1 - f1 + 0.01)
              for (j = [0 : n - 1])
                rotate([0, 0, (j + (k % 2) * 0.5) * 360 / n])
                    translate([core_d / 2, 0, zc])
                        rotate([0, 90, 0])
                            linear_extrude(height = h, scale = s)
                                circle(r = rb, $fn = 6);
        }
    }
}

module ring_seat() {
    // short cylinder with a small raised lip on the outer edge to stop the ring sliding off
    cylinder(d = ring_seat_d, h = ring_seat_len);
    translate([0, 0, ring_seat_len - 1.2])
        cylinder(d = ring_seat_d + 2 * ring_groove_d, h = 1.2);
}

module grip_outer() {
    if (inboard_ring) {
        ring_seat();
    }

    knurled();

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

// Solid frame following the logo outline: fills the hex pockets around the lines
module logo_borders() {
    for (p = [[logo_a, logo_a_z, logo_a_angle, logo_a_rot],
                [logo_b, logo_b_z, logo_b_angle, logo_b_rot]])
        if (p[0] != "")
            intersection() {
                envelope();
                radial(p[2], p[1], body_d / 2 + bulge + 1)
                    offset(delta = logo_border) rotate(p[3]) logo2d(p[0]);
            }
}

module logo_engravings() {
    for (p = [[logo_a, logo_a_z, logo_a_angle, logo_a_rot],
                [logo_b, logo_b_z, logo_b_angle, logo_b_rot]])
        if (p[0] != "")
            difference() {
                radial(p[2], p[1], body_d / 2 + bulge + 2) rotate(p[3]) logo2d(p[0]);
                envelope(-logo_depth);   // keep the logos inside the pattern span
            }
}

module grip() {
    difference() {
        union() { grip_outer(); logo_borders(); }
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
