#!/usr/bin/env bash
# Turn the artwork in source/ into PNGs in build/ that lib_bookmark.scad can read.
#   build/<name>.png    clean black/white mask (white = material, black = gap)
#   build/<name>_h.png  height profile: black = no material, white edge pixels ramp
#                       up through a rounded fillet of EDGE_R mm, then go flat.
#                       lib_bookmark.scad mirrors it, so both faces get rounded edges.
#   ./prep_images.sh            all images
# Env: PX_H=900   pixel height of the output (more = smoother edges, slower render)
#      EDGE_R=0.3 edge fillet radius in mm
# The size table at the bottom must match h/t in <name>_bookmark.scad.
# Needs ImageMagick (`magick`).
set -euo pipefail
cd "$(dirname "$0")"
px_h="${PX_H:-900}"
edge_r="${EDGE_R:-0.3}"
mkdir -p build

# height <name> <h_mm> <t_mm>: build/<name>_h.png from build/<name>.png
#   Blur the mask (soft anti-aliased edge), turn the ramp into a quarter-circle
#   fillet, flat at 1 inside; black stays 0. Values are fractions of t/2.
height() {
    local name="$1" h_mm="$2" t_mm="$3"
    local px_mm sigma base
    px_mm=$(magick identify -format "%[fx:h/$h_mm]" "build/$name.png")
    sigma=$(awk -v p="$px_mm" -v r="$edge_r" 'BEGIN { printf "%.3f", p * r / 2 }')
    base=$(awk -v t="$t_mm" -v r="$edge_r" 'BEGIN { printf "%.4f", 1 - r / (t / 2) }')
    magick "build/$name.png" \( +clone -blur "0x$sigma" \) \
        -fx "uu=min(max((v-0.5)*2,0),1); u*($base+(1-$base)*sqrt(1-(1-uu)*(1-uu)))" \
        -depth 8 -type Grayscale -define png:color-type=0 -define png:bit-depth=8 "build/${name}_h.png"
    echo "build/${name}_h.png  ${px_mm} px/mm, blur sigma ${sigma}px, flat at ${base}"
}

# prep <source> <name> [fill_outside]
#   fill_outside=1: the artwork has a white background around its outline, so
#   flood the outside with black (cut from the outline inwards).
prep() {
    local src="$1" name="$2" fill_outside="${3:-0}"
    local args=(-colorspace Gray -threshold 50% -depth 8 -type Grayscale -define png:color-type=0 -define png:bit-depth=8)
    if [[ "$fill_outside" == 1 ]]; then
        args+=(-bordercolor white -border 1 -fill black -draw "color 0,0 floodfill" -shave 1x1)
    fi
    args+=(-bordercolor black -border 1 -trim +repage -resize "x${px_h}" -threshold 50% -depth 8 -type Grayscale -define png:color-type=0 -define png:bit-depth=8)
    magick "$src" "${args[@]}" "build/$name.png"
    echo "build/$name.png  $(magick identify -format '%wx%h' "build/$name.png")"
}

prep source/cat_pattern.jpeg  cat
prep source/fish_pattern.jpeg  fish 1

#      name  h_mm  t_mm   (match h and t in <name>_bookmark.scad)
height cat   176   2
height fish  176   2
