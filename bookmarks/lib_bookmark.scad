// Helpers for image-based bookmarks (not rendered on its own; `use` it).
// An image (white = material, black = gap) becomes a flat plate with the black
// areas cut through. Prepare images with ./prep_images.sh first.
//
//   image2d(file, w, h, smooth)         2D shape of the white pixels, scaled to w x h mm,
//                                       corners rounded by `smooth` mm (removes pixel steps)
//   hole2d(d, w, h, inset)              round hanging hole near the top, centred
//   bookmark(file_h, w, h, t, hole_d)   the finished plate, t mm thick, edges rounded in
//                                       cross-section (uses build/<name>_h.png)
//   bookmark_flat(file, w, h, t, hole_d, smooth)  plain extrusion of the mask, sharp edges
//   bookmark_relief(file, w, h, t, relief)  solid backing plate + raised artwork

// White pixels as a 2D shape, scaled so its bounding box is exactly w x h.
// surface() reads brightness as height (0..100), so slicing at 50 keeps white.
// `smooth` (mm) rounds corners and removes the one-pixel steps: the shape is
// opened then closed by that radius. Features thinner than 2*smooth vanish,
// so keep it below half of the thinnest line (0 = off).
module image2d(file, w, h, smooth = 0.1) {
    module raw() {
        resize([w, h])
            projection(cut = true)
                translate([0, 0, -50])
                    surface(file = file, center = true);
    }
    if (smooth > 0)
        offset(r = -smooth, $fn = 16) offset(r = smooth, $fn = 16)   // closing
            offset(r = smooth, $fn = 16) offset(r = -smooth, $fn = 16) // opening
                raw();
    else
        raw();
}

// Hanging hole for a tassel, centred horizontally, `inset` mm below the top edge.
module hole2d(d, w, h, inset = 6) {
    translate([0, h / 2 - inset]) circle(d = d, $fn = 48);
}

// Plate with the artwork's gaps cut through and rounded edges. The height map
// (build/<name>_h.png) holds the profile as a fraction of t/2: surface() builds
// the top half, it is mirrored for the bottom, and the result is trimmed to the
// footprint of the artwork (black pixels would otherwise leave a paper-thin film).
// Footprint and profile come from the same data, so they stay aligned; everything
// is scaled to w x h x t together. 2D origin is the plate centre.
// cut_level (0..100) is the height at which the footprint is traced: it must be
// below the flat level (100 * (1 - edge_r / (t/2))), the default suits edge_r 0.3, t 2.
module bookmark(file_h, w, h, t = 2, hole_d = 0, cut_level = 30) {
    module half() { surface(file = file_h, center = true); }
    difference() {
        resize([w, h, t])
            intersection() {
                union() { half(); mirror([0, 0, 1]) half(); }
                linear_extrude(height = 400, center = true)
                    projection(cut = true) translate([0, 0, -cut_level]) half();
            }
        if (hole_d > 0)
            translate([0, h / 2 - 6, -t]) cylinder(d = hole_d, h = 2 * t, $fn = 48);
    }
}

// Plate with the artwork's gaps cut through, plain extrusion (sharp edges).
module bookmark_flat(file, w, h, t = 1.6, hole_d = 0, smooth = 0.1) {
    linear_extrude(height = t)
        difference() {
            image2d(file, w, h, smooth);
            if (hole_d > 0) hole2d(hole_d, w, h);
        }
}

// Alternative: thin solid backing (convex hull of the artwork, holes filled in)
// with the artwork raised on top. Good for single-colour bookmarks that
// need to stay flat on the page.
module bookmark_relief(file, w, h, t = 0.8, relief = 0.8, hole_d = 0, smooth = 0.1) {
    linear_extrude(height = t)
        difference() {
            hull() image2d(file, w, h, smooth);
            if (hole_d > 0) hole2d(hole_d, w, h);
        }
    translate([0, 0, t - 0.01])
        linear_extrude(height = relief + 0.01)
            difference() {
                image2d(file, w, h, smooth);
                if (hole_d > 0) hole2d(hole_d, w, h);
            }
}
