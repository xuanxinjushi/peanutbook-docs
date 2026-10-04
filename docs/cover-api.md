# Cover rendering API (`bubble.cover_*`)

Peanutbook ships reusable Python helpers for **print full-wrap covers** (back + spine + front). They live in the `bubble` package under `shared/bubble/` and are used by project scripts such as `cover/7x10/cover_back_v2_draw.py`, `gen_fullcover.py`, and `full_cover_from_front_back_en.py`.

Install peanutbook (or add `shared/` to `PYTHONPATH`) and import from `bubble`:

```python
from bubble.cover_fonts import get_cover_font_path, load_font, wrap_words
from bubble.cover_draw import draw_bullet_dot_pil, wrap_bullet_list
from bubble.cover_print import get_cover_spec, spread_pixels
```

## Module overview

| Module | Purpose |
|--------|---------|
| `bubble.cover_draw` | List bullets (matplotlib + PIL), semi-opaque rounded boxes, inch→pixel helpers |
| `bubble.cover_fonts` | Western serif font stack, PIL `load_font`, word wrap |
| `bubble.cover_export` | `save_small_jpeg` — KDP/web preview thumbnails |
| `bubble.cover_print` | Vendor print specs (`CoverPrintSpec`, `spread_pixels`) + bundled JSON |
| `bubble.cover_image` | Lower-band dimming (`dim_image_lower`) for background PNGs |
| `bubble.cover_spread` | Panel paste into bleed slots, spine photos, background recompose |
| `bubble.cover_spine` | Spine bridge/fog masks, rotated spine typography |
| `bubble.cover_background` | Low-poly Delaunay panel backgrounds + math watermarks |

Book-specific layout (copy, colors, positions) stays in `cover/{size}/` scripts. Shared geometry and drawing primitives live in `bubble`.

---

## `bubble.cover_print`

Loads dimensions from `bubble/data/cover_print_config.json` (shipped with the package). Projects can override by passing `config_path` or keeping a local `cover_print_config.json` (as in `cover/7x10/`).

### Key types

- **`CoverPrintSpec`** — full spread size in inches + dpi (`provider`, bleed, panel trim, spine width).
- **`SpreadPixels`** — pixel layout derived from a spec (`back_x0`, `spine_x0`, `front_x0`, `panel_w`, `spine_px`, content centers).

### Functions

```python
from pathlib import Path
from bubble.cover_print import (
    get_cover_spec,
    get_default_provider,
    list_providers,
    normalize_provider,
    provider_slug,
    spread_pixels,
    guess_cover_spec_from_size,
    default_config_path,
)

spec = get_cover_spec("en", provider="kdp/paperback")
px = spread_pixels(spec)
# px.total_w, px.back_x0, px.front_content_cx, ...

# Optional: project-local JSON
local = Path("cover/7x10/cover_print_config.json")
spec = get_cover_spec("en", provider="ingram/hardcover", config_path=local)
```

**Provider IDs** use `vendor/binding` form, e.g. `kdp/paperback`, `ingram/hardcover`. Legacy aliases `kdp_paperback`, `ingram_hardcover` are accepted.

`bubble-batch` and `gen_fullcover.py` use the same provider strings via `--cover-provider`.

---

## `bubble.cover_fonts`

Resolves a Western serif font file (EB Garamond preferred) and loads it for PIL at a given point size and dpi.

```python
from bubble.cover_fonts import (
    SERIF_EN_DEFAULT,
    get_cover_font_path,
    load_font,
    wrap_words,
    pt2px,
    text_bbox,
)

from PIL import ImageDraw, Image

font_path = get_cover_font_path()
body = load_font(font_path, 12.8, dpi=300)
draw = ImageDraw.Draw(Image.new("RGB", (800, 200)))
lines = wrap_words(draw, "Long paragraph …", body, max_width_px=600)
```

---

## `bubble.cover_draw`

### Bullets

EB Garamond’s Unicode bullet (`U+2022`) renders as a hollow square in PIL. Use **drawn circular bullets** instead:

```python
from bubble.cover_draw import (
    BULLET_CHAR,
    BULLET_SCALE_DEFAULT,
    BULLET_STROKE_PT,
    bullet_text_indent_px,
    draw_bullet_dot_pil,
    wrap_bullet_list,
    draw_wrapped_bullets_pil,
)

content = "• First item\n• Second item"
indent = bullet_text_indent_px(12.8, dpi=300)
rows = wrap_bullet_list(draw, content, font, max_w, indent, wrap_words)
for need_bullet, line in rows:
    if need_bullet:
        x = draw_bullet_dot_pil(draw, x0, y, 12.8, (255, 255, 255), 300)
    ...
```

Or one-shot: `draw_wrapped_bullets_pil(...)`.

Matplotlib back covers can use `body_text_with_bullets` and `draw_bullet_dot` on an axes object.

### Layout primitives

```python
from bubble.cover_draw import draw_semiopaque_rounded_rect, y_from_bottom_in_to_px

y = y_from_bottom_in_to_px(3.25, y0, panel_h_px, dpi=300)  # inches from bottom
draw_semiopaque_rounded_rect(img, x, y, w, h, radius_px, alpha=0.75)
```

---

## `bubble.cover_export`

```python
from bubble.cover_export import save_small_jpeg, SMALL_JPEG_LINEAR_SCALE

preview = save_small_jpeg(full_cover_img, Path("out/cover.jpg"), dpi=300)
# → out/cover_small.jpg at ~0.33× linear scale
```

---

## `bubble.cover_image`

Soft darkening of the **lower band** of a cover background (numpy array or file pipeline):

```python
from bubble.cover_image import dim_image_lower, write_lower_band_bkg

arr = dim_image_lower(arr, frac_lower=0.2, brightness_factor=0.13)
write_lower_band_bkg("cover_front_bkg.png", "cover_front_bkg_v2.png", input_dir=Path("input"))
```

CLI (from a book repo): `python cover/7x10/image_lower_band.py` still works; it delegates to `bubble.cover_image`.

---

## `bubble.cover_spread`

Full-wrap assembly helpers:

```python
from bubble.cover_spread import (
    paste_panels_into_bleed_slots,
    synthesize_bleed_from_inner_edge,
    fit_spine_top_photo,
    paste_spine_photo_top,
    load_bkg_for_spec,
    recompose_bkg_for_target,
    pil_resample_lanczos,
    is_hardcover_provider,
)

rs = pil_resample_lanczos()
paste_panels_into_bleed_slots(canvas, back_panel, front_panel, spread_pixels(spec), rs)

# Resize a KDP spread PNG to Ingram hardcover geometry
img = load_bkg_for_spec(Path("out/_bkg/spread_kdp_paperback_en.png"), target_spec, "en", resample=rs)
```

---

## `bubble.cover_spine`

Spine **bridge** compositing between back and front panels, plus **rotated** title/subtitle/author text (default 270° CCW):

```python
from bubble.cover_spine import (
    make_bridge_base,
    flat_top_spine_mask,
    edge_zero_fog_mask,
    draw_spine_title_lines,
    draw_rotated_spine_text_top,
    spine_safe_band,
    measure_rotated_text_block,
)

bridge = make_bridge_base(back, front, edge_fog_w, spine_px, panel_w, panel_h, resample)
top, bottom, title_y = spine_safe_band(by0, panel_h, center_inset_frac=0.08, photo_zone_h_px=260)
y = draw_spine_title_lines(canvas, title_lines, spine_cx, title_y, title_font, rotate_deg=270)
```

---

## `bubble.cover_background`

Low-poly Delaunay triangulation backgrounds (matplotlib → PIL). Two fill modes:

- **`LowPolyGradientStyle`** — horizontal two-color blend + jitter (v2 dark covers)
- **`LowPolyColormapStyle`** — radial matplotlib colormap (legacy light covers, e.g. `viridis_r`)

Optional **`MathWatermarkStyle`** scatters faint `$…$` labels (uses `math4ai.configure_math_fonts` when available).

```python
from bubble.cover_background import (
    LowPolyGradientStyle,
    MathWatermarkStyle,
    LowPolyColormapStyle,
    render_low_poly_panel,
)

img = render_low_poly_panel(
    7.0, 10.0, 300,
    gradient=LowPolyGradientStyle(
        grad_left=(0.04, 0.20, 0.17),
        grad_right=(0.16, 0.07, 0.18),
    ),
    watermark=MathWatermarkStyle(symbols=(r"$A = QR$", r"$\nabla f$")),
    seed=42,
    mirror_x=False,  # True for back panel (gradient toward spine)
)

# Legacy viridis radial style (cover_front.py)
img_light = render_low_poly_panel(
    7.0, 10.0, 300,
    colormap=LowPolyColormapStyle(colormap="viridis_r"),
    seed=42,
)
```

`cover/7x10/cover_front_v2_draw.py` passes book-specific `LOW_POLY_STYLE` and `MATH_WATERMARK` into this API.

---

## Typical project layout

```
cover/7x10/
  constant_text.py          # book copy (titles, features, spine strings)
  cover_print_config.json   # optional override of bundled print sizes
  cover_back_v2_draw.py     # back panel layout (imports bubble.*)
  cover_front_v2_draw.py    # front panel + low-poly background
  full_cover_from_front_back_en.py  # spread background + spine
  gen_fullcover.py          # overlay text on spread cache
  out/_bkg/spread_*_en.png  # intermediate spread cache (not a deliverable)
  cover_print_config.py     # thin re-export → bubble.cover_print (local JSON default)
  cover_export.py           # thin re-export → bubble.cover_export
```

Regenerate English 7×10 back cover:

```bash
cd cover/7x10
PYTHONPATH=../../shared:$PYTHONPATH python cover_back_v2_draw.py
```

Full spread with provider:

```bash
python full_cover_from_front_back_en.py --provider ingram/hardcover
python gen_fullcover.py --provider ingram/hardcover
```

See also **[Covers & templates](covers-templates.md)** for CLI (`bubble-batch --cover-provider`) and template mapping.
