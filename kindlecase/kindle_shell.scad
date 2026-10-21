// ====================================================
// Kindle 10th Gen Basic (J9G29R) Sleeve Generator
// True Half-Circle Thumb Scoops (Depth = Radius)
// Dimensions: 160 x 113 x 8.7 mm
//
// kindle_shell()  - the full case (default render)
// test_ring()     - a slice cut from the middle of the very same case,
//                   so the ring always matches the case exactly
// ====================================================

$fn = 80; // High resolution for smooth curves

// Kindle Exact Dimensions
k_height = 160.0;
k_width  = 113.0;
k_thick  = 8.7;
k_radius = 8.5; // Corner radius of Kindle body

// Tolerances & Shell Properties
clearance   = 0.6; // Inner clearance (+0.6mm total for smooth glide)
wall_thick  = 2.2; // Rigid outer wall thickness

// True Half-Circle Cutout Geometry (Depth equals Radius)
scoop_radius = 15.0; // Radius of the semi-circle
scoop_depth  = 0.0; // 0 = circle centered on the top edge, i.e. a true half-circle

// Edge rounding of the faces (inner cavity; outer adds wall_thick for even walls)
edge_radius = 2.0; // must be <= k_radius and < in_t / 2

// Test ring
ring_height = 3.0;  // Slice thickness (min sensible ~3mm: 2.2mm wall, 15 layers at 0.2)
ring_y      = 70.0; // Where along the case height to cut (clear of bottom wall and scoops)

// Calculated Inner Cavity Dimensions
in_w = k_width + clearance;
in_h = k_height + clearance;
in_t = k_thick + clearance;

// Outer Shell Dimensions
out_w = in_w + (wall_thick * 2);
out_h = in_h + wall_thick;
out_t = in_t + (wall_thick * 2);

// Box with plan-view corner radius r and rounded face edges (radius e, e <= r, e <= t/2)
module rounded_cube(w, h, t, r, e) {
    module corner() {
        rotate_extrude()
            hull() {
                square([0.01, t]);
                translate([r - e, e]) circle(r=e);
                translate([r - e, t - e]) circle(r=e);
            }
    }
    hull() {
        translate([r, r, 0]) corner();
        translate([w - r, r, 0]) corner();
        translate([r, h - r, 0]) corner();
        translate([w - r, h - r, 0]) corner();
    }
}

module kindle_shell() {
    difference() {
        // 1. Main Outer Shell
        rounded_cube(out_w, out_h, out_t, k_radius + wall_thick, edge_radius + wall_thick);

        // 2. Hollow Inner Cavity for Kindle
        translate([wall_thick, wall_thick, wall_thick])
            rounded_cube(in_w, in_h + 10, in_t, k_radius, edge_radius);

        // 3. Front True Half-Circle Scoop
        translate([out_w / 2, out_h - scoop_depth, out_t + 1])
            cylinder(r=scoop_radius, h=wall_thick * 4, center=true);

        // 4. Back True Half-Circle Scoop (Symmetrical)
        translate([out_w / 2, out_h - scoop_depth, -1])
            cylinder(r=scoop_radius, h=wall_thick * 4, center=true);
    }
}

module test_ring() {
    // Slice the case across its height, then lay the slice flat for printing
    translate([0, 0, ring_height])
        rotate([-90, 0, 0])
            translate([0, -ring_y, 0])
                intersection() {
                    kindle_shell();
                    translate([-1, ring_y, -1])
                        cube([out_w + 2, ring_height, out_t + 2]);
                }
}

kindle_shell();
