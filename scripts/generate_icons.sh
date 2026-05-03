#!/bin/bash
#
# generate_icons.sh
# Generates the iOS AppIcon set from whitman-logo.svg using the iOS 18+
# single-size 1024x1024 layout. iOS scales the 1024 master down to every
# device size at install time, so we no longer ship per-size PNGs.
#
# Variants:
#   - Light (default):    pale-blue background, original figure colors
#   - Dark (luminosity):  same figure colors as light, but transparent
#                         background so iOS's dark home-screen platter shows
#                         through. No path recoloring — the asymmetric source
#                         geometry made color-swap dark recolors look uneven.
#   - Tinted (luminosity): white silhouette on transparent for iOS to recolor

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

SRC_SVG="whitman-logo.svg"
ASSETS_DIR="LeavesOfBlocks/Assets.xcassets/AppIcon.appiconset"
TMP_DIR="tmp"

# Background color for the light variant. Matches the prior logo.svg wrapper
# (a soft autumn-sky blue) so the App Store icon visually doesn't change.
LIGHT_BG="#E0EAF2"

# Square viewBox that pads the figure (figure's own viewBox is "219 159 589
# 713"). 113.5/115.5 + 800x800 leaves comfortable breathing room around the
# Whitman silhouette inside the iOS rounded-corner mask.
WRAPPED_VIEWBOX="113.5 115.5 800 800"
WRAPPED_RECT_X="113.5"
WRAPPED_RECT_Y="115.5"
WRAPPED_RECT_SIZE="800"

if ! command -v rsvg-convert &>/dev/null; then
    echo "Error: rsvg-convert is required but not installed." >&2
    echo "  Install with: brew install librsvg" >&2
    exit 1
fi

if [ ! -f "$SRC_SVG" ]; then
    echo "Error: $SRC_SVG not found in $(pwd)" >&2
    exit 1
fi

mkdir -p "$TMP_DIR"

# Pull out the inner content of whitman-logo.svg so we can rewrap it with our
# own outer <svg> element per variant (each variant needs a different
# viewBox/background/color palette).
INNER_FILE="$TMP_DIR/.inner.svg"
sed -E 's|^[[:space:]]*<\?xml[^?]*\?>||' "$SRC_SVG" \
    | sed -E 's|<svg[^>]*>||' \
    | sed -E 's|</svg>[[:space:]]*$||' > "$INNER_FILE"

write_outer() {
    # write_outer <output-svg> <bg-or-"transparent"> <inner-svg-fragment>
    local out="$1"
    local bg="$2"
    local inner_path="$3"

    {
        echo '<?xml version="1.0" encoding="utf-8" ?>'
        echo "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"$WRAPPED_VIEWBOX\">"
        if [ "$bg" != "transparent" ]; then
            echo "<rect x=\"$WRAPPED_RECT_X\" y=\"$WRAPPED_RECT_Y\" width=\"$WRAPPED_RECT_SIZE\" height=\"$WRAPPED_RECT_SIZE\" fill=\"$bg\"/>"
        fi
        cat "$inner_path"
        echo '</svg>'
    } > "$out"
}

# --- Light variant ---------------------------------------------------------
# Opaque pale-blue background, original figure colors.
write_outer "$TMP_DIR/icon-light.svg" "$LIGHT_BG" "$INNER_FILE"

# --- Dark variant ----------------------------------------------------------
# Same figure as the light variant, just rendered onto iOS's dark home-screen
# platter (transparent background, no path recoloring).
write_outer "$TMP_DIR/icon-dark.svg" "transparent" "$INNER_FILE"

# --- Tinted variant --------------------------------------------------------
# Transparent background, every fill flattened to white. iOS recolors white
# pixels with the user's chosen tint, producing a single-tone silhouette.
TINTED_INNER="$TMP_DIR/.inner-tinted.svg"
sed -E \
    -e 's|fill="#[0-9A-Fa-f]{6}"|fill="#FFFFFF"|g' \
    -e 's|fill="url\([^)]*\)"|fill="#FFFFFF"|g' \
    "$INNER_FILE" > "$TINTED_INNER"
write_outer "$TMP_DIR/icon-tinted.svg" "transparent" "$TINTED_INNER"

# Render the variant SVGs to 1024x1024 PNGs.
echo "Rendering icon variants from $SRC_SVG..."
rsvg-convert -w 1024 -h 1024 "$TMP_DIR/icon-light.svg"   > "$TMP_DIR/AppIcon-1024.png"
rsvg-convert -w 1024 -h 1024 "$TMP_DIR/icon-dark.svg"    > "$TMP_DIR/AppIcon-1024-Dark.png"
rsvg-convert -w 1024 -h 1024 "$TMP_DIR/icon-tinted.svg"  > "$TMP_DIR/AppIcon-1024-Tinted.png"
echo "  ✓ tmp/AppIcon-1024.png"
echo "  ✓ tmp/AppIcon-1024-Dark.png"
echo "  ✓ tmp/AppIcon-1024-Tinted.png"

# Sweep stale icons (legacy per-size PNGs and any prior dark variant) out of
# the appiconset — only the entries referenced by the new Contents.json
# should remain on disk.
mkdir -p "$ASSETS_DIR"
echo ""
echo "Cleaning stale icons from $ASSETS_DIR..."
shopt -s nullglob
for legacy in "$ASSETS_DIR"/AppIcon-*.png; do
    case "$(basename "$legacy")" in
        AppIcon-1024.png|AppIcon-1024-Dark.png|AppIcon-1024-Tinted.png) ;;
        *)
            rm -f "$legacy"
            echo "  Removed $(basename "$legacy")"
            ;;
    esac
done

cp "$TMP_DIR/AppIcon-1024.png"        "$ASSETS_DIR/AppIcon-1024.png"
cp "$TMP_DIR/AppIcon-1024-Dark.png"   "$ASSETS_DIR/AppIcon-1024-Dark.png"
cp "$TMP_DIR/AppIcon-1024-Tinted.png" "$ASSETS_DIR/AppIcon-1024-Tinted.png"

cat > "$ASSETS_DIR/Contents.json" <<'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "AppIcon-1024-Dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "AppIcon-1024-Tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo "✅ App icons regenerated from $SRC_SVG"
echo "📁 $ASSETS_DIR"
echo "    AppIcon-1024.png         (light: pale-blue background, original colors)"
echo "    AppIcon-1024-Dark.png    (transparent: original colors on iOS dark platter)"
echo "    AppIcon-1024-Tinted.png  (transparent: white silhouette for system tinting)"
