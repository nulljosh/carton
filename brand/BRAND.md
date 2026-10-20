# Cartons brand

Cartons tracks packages and leads with one number: days until it arrives. The brand is the box itself.

## Icon
The whole tile is a kraft carton: packing tape over the top seam, a shipping label with a barcode, corrugated grain. No background, no symbol in the middle. `Cartons.icon` is the source of truth, in three layers: board (`base.png`, with `base-dark.png` swapped in for dark mode through hidden-specializations), tape and label, the last two with glass on so the system lights them. The layer SVGs live in `brand/src/layers/`, cut from `brand/src/box.svg`. Preview any rendition with `ictool Cartons.icon --export-image --rendition Default|Dark|TintedDark` (Icon Composer's CLI); `brand/icon-variants.png` shows all three. `brand/icon-1024.png` is the flat fallback (no alpha). Never redraw it as a flat glyph.

## Colour
| Token | Hex | Use |
|---|---|---|
| Kraft | `#c88f55` | the brand colour, box front |
| Kraft light | `#e8bd86` | box top, hover |
| Kraft deep | `#8c5a2c` | actions, links, countdown digits (6.4:1 on paper) |
| Tape | `#f0d39d` | highlights, selection |
| Paper | `#fdfbf7` | page ground, label stock |
| Ink | `#2b1a0b` | text |

Dark mode swaps paper for `#17120d` and lifts the accent to `#e0a96d`. Pages stay mostly white: brown is for the box, the route and actions, never a full-bleed ground.

## Type
Cartons Sans is the one face: Inter (OFL) renamed by `scripts/gen_font.py`, a plain screen sans between San Francisco, Helvetica and Lato. Four weights, proportional figures. Bold for the wordmark, Semibold for countdown digits and titles, Regular for reading. A stencil face was tried and dropped; keep it plain.

## Shape
8 point grid. Controls are 48 point capsules. Cards 28, grouped lists 20. One radius set, one shadow.

## Voice
Short and plain. Say the date, say the days, stop. "7 days" beats "Your package is estimated to arrive in approximately one week."
