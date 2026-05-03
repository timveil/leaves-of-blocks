# Game Center Achievement Image Prompts

Recraft prompts for the five Game Center achievements defined in
`fastlane/GameCenterConfig.rb` and `LeavesOfBlocks/Services/Game/GameCenterService.swift`.

## Apple's spec

- **Size:** 1024×1024 PNG
- **No alpha channel** — App Store Connect rejects images with transparency.
  If Recraft exports with alpha, flatten in Preview ("Export As… PNG", uncheck
  "Include alpha") or via ImageMagick:
  `magick input.png -background "#FBF6EC" -alpha remove output.png`
- **Centered subject with ~10% safe margin** — Apple crops to a circle in most
  UI surfaces, so corners are often hidden.
- **No text, letters, or numbers** in the image — Apple displays the
  achievement name itself; embedding it would duplicate.
- **Test at 64×64.** Scale each PNG down in Preview and check legibility. If the
  subject is unreadable at thumbnail size, the composition is too busy.

## Shared style guidance

Append this block to every prompt so all five images share line weight,
palette, and texture:

```
Style: modern folk-art digital illustration, flat colors with subtle paper-grain
texture, bold clean black ink outlines (consistent medium line weight, slightly
hand-drawn but tidy). No gradients, no photorealism, no 3D, no shading. Square
1:1 composition, 1024×1024, strong central focal point readable when cropped
to a 64×64 circle. No text, no letters, no numbers anywhere in the image.

Color palette: warm cream paper background (#FBF6EC), deep slate ink outlines
(#1F2837), autumn-leaf orange (#DB8732), poppy red (#C6533F), saffron gold
(#CD9A3D), teal-blue (#15756F), leaf green (#3D8A4F), warm sienna brown
(#623730). Match the palette of a stylized illustrated portrait of Walt Whitman
(navy coat, brown hat, cream beard) and an autumn tree scene with falling
leaves over a pale dusty-blue sky.

Recraft style preset: Digital Illustration → Hand Drawn (or Flat 2 / 2D Art).
```

## Prompts

### 1. `lob.ach.firstClear` — "First Clear"

> *"every leaf finds its place"*

```
A single autumn leaf, slightly tilted as if just landing, resting perfectly
inside one square of an empty grid pattern. The leaf is a stylized
folk-art maple or oak shape in saffron gold and orange with a visible black
ink stem and central vein. The grid behind it is faint, drawn in pale slate
lines on warm cream paper, suggesting an 8×8 puzzle board fading into the
edges. A few smaller leaves drift softly in the negative space around it.
Centered composition, the landed leaf the clear hero of the image.

[append shared style guidance]
```

### 2. `lob.ach.combo4` — "Combo Master"

> *"Four lines, one move — patience, then power"*

```
A central square block placed at the heart of the image, with four bold
ink-lined burst rays radiating outward — up, down, left, right — each ray
formed by a row of stylized autumn leaves caught mid-launch. The block is
a flat teal-blue square with a clean black outline. The four leaf-rays use
contrasting colors: orange leaves above, red leaves below, gold leaves left,
green leaves right, all drawn in the same folk-art outlined style.
Background is warm cream paper with faint radial motion lines suggesting
energy without being busy. Bold, dynamic, but uncluttered.

[append shared style guidance]
```

### 3. `lob.ach.efficiencyAPlus` — "Efficient as Autumn"

> *"Few wasted cells. The grid breathed easy under your hand"*

```
A neatly composed cluster of seven or eight square puzzle blocks fitted
together perfectly to form a single larger square — no gaps, no overhangs,
each block a different color from the autumn palette (teal-blue, leaf-green,
tomato-red, saffron-gold, sienna-brown, coral-orange). Each block has a
crisp black ink outline. Above the tidy cluster a single calm autumn leaf
floats — a quiet exhale. The cream paper background has a faint ghost of
the puzzle grid behind everything. Composition is symmetric and serene,
emphasizing order and rightness.

[append shared style guidance]
```

### 4. `lob.ach.strategicMaster` — "Strategic Master"

> *"Each block placed with intention — a quiet kind of mastery"*

```
A bust-up portrait of an old bearded man in profile (left-facing), wearing
a wide-brimmed brown hat and a dark navy coat with an orange shirt
underneath, his cream-white beard flowing over his chest. He is gazing
thoughtfully downward at a small floating arrangement of three connected
puzzle blocks (teal, gold, green) hovering in front of his shoulder, as if
contemplating a move. The portrait is stylized, flat, with clean black ink
outlines — drawn in the exact style of a children's-book Walt Whitman.
Pale dusty-blue background. Calm, contemplative, intentional.

[append shared style guidance]
```

*This intentionally echoes the app icon so the achievement reads as "the
master himself approves."*

### 5. `lob.ach.score10k` — "Ten Thousand Leaves"

> *"Ten thousand points — the orchard is full"*

```
A single full-canopy autumn tree, centered, with a thick warm-sienna trunk
and an enormous round crown overflowing with stylized folk-art leaves in
orange, red, gold, and pockets of teal-green. Dozens of small leaves spill
from the crown and drift downward, filling the lower third of the image
with a generous, abundant cascade. A small grass mound in coral-green sits
at the trunk's base. Pale dusty-blue sky background. The tree should feel
heavy with abundance — full, generous, harvest-ready. Symmetrical and
calm; the abundance reads at a glance even at thumbnail size.

[append shared style guidance]
```

## Workflow tips

- Generate all five in the same Recraft project/style preset. Inconsistency
  between achievements is more jarring than any single image being imperfect.
- Run each prompt 3–4 times, pick the strongest, then ask Recraft to "make a
  variation" of the chosen one if you want fine-tuning.
- After downloading, do the 64×64 thumbnail test before uploading to App Store
  Connect.

## Uploading

Achievement images go in App Store Connect → your app → Game Center →
Achievements → (each achievement) → Image. Both "before earned" (locked) and
"after earned" can use the same image; some apps prefer a desaturated/grayscale
variant for the locked state. If you want locked variants, generate the colored
version first, then desaturate in Preview or with:
`magick colored.png -modulate 100,0,100 locked.png`
