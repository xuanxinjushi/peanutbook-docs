# Cover rendering API (`bubble.cover`)

Peanutbook ships reusable Python helpers for **print covers** — standalone
front/back panels and full-wrap (back + spine + front) covers. They live in
the `bubble.cover` subpackage (repo root: `cover/`) and are used by the
scaffolded `templates/cover_front.py` / `cover_back.py`, by the
[Cover Designer web app](cover-designer.md), and by the image-pattern
gallery tests.

Install peanutbook and import from `bubble.cover`:

```python
from bubble.cover.fonts import get_cover_font_path, load_font, wrap_words
from bubble.cover.draw import draw_bullet_dot_pil, wrap_bullet_list
from bubble.cover.print_spec import get_cover_spec, spread_pixels
```

!!! note "Not the same `cover/` as a book project's"
    A book project also has its own `cover/{size}/` directory holding that
    book's cover PDFs and Python drawing scripts (see
    [Covers & templates](covers-templates.md)). That is unrelated to *this*
    `cover/` — the directory name is shared, but this one is peanutbook's own
    source package (`bubble.cover`), not book-specific content.

## Module overview

| Module | Purpose |
|--------|---------|
| `bubble.cover.render` | The "code" pattern's front/back drawing (`draw_front_cover`, `draw_back_cover`) |
| `bubble.cover.full_cover` | Full wrap-cover assembly: real KDP/Ingram/Lulu geometry, spine fogging, rotated spine text, logo placement |
| `bubble.cover.code_presets` | Named background presets for the "code" pattern (`midnight`, `low-poly`, `minimal-light`, `corporate-blue`) |
| `bubble.cover.print_spec` | Vendor print specs (`CoverPrintSpec`, `spread_pixels`, `list_providers`) + bundled JSON |
| `bubble.cover.text` | Locale-aware font resolution, text wrap, `peanut.config` reading — shared by the scaffolded templates |
| `bubble.cover.fonts` | PIL font resolution, CJK detection, word wrap |
| `bubble.cover.draw` | Matplotlib/PIL bullets, semi-opaque rounded boxes, inch→pixel helpers |
| `bubble.cover.export` | `save_small_jpeg` — KDP/web preview thumbnails |
| `bubble.cover.image` | Lower-band dimming (`dim_image_lower`) for background PNGs |
| `bubble.cover.spread` | Panel paste into bleed slots, spine photos, background recompose |
| `bubble.cover.spine` | Spine bridge/fog masks, rotated spine typography |
| `bubble.cover.background` | Low-poly Delaunay panel backgrounds, flat/gradient panels, math watermarks |
| `bubble.cover.barcode` | EAN-13 ISBN barcode generation |

Book-specific layout (copy, colors, positions) stays in a project's
`cover/{size}/` scripts (or in the Cover Designer's saved fields). Shared
geometry and drawing primitives live in `bubble.cover`.

---

## `bubble.cover.render`

The "code" pattern's actual drawing — shared by `templates/cover_front.py` /
`cover_back.py` (which read their parameters from `peanut.config` and
delegate here) and by any other caller, such as the Cover Designer's
rendering bridge, that already has title/subtitle/author/etc. as plain
values rather than a config file to read.

```python
from bubble.cover.render import draw_front_cover, draw_back_cover

draw_front_cover(
    "cover_front.pdf",
    title="My Book Title", subtitle="A Subtitle", author="Author Name",
    publisher="My Press", year="2026", lang="en", preset_name="midnight",
)
draw_back_cover(
    "cover_back.pdf",
    body="Back-cover jacket copy…", publisher="My Press",
    website="https://example.com",
)
```

---

## `bubble.cover.full_cover`

Full wrap-cover (back + fogged spine + front) assembly — the mechanism
(real print geometry, spine fogging, rotated spine text, logo placement)
lives here exactly once, shared by the image-pattern gallery test and by the
Cover Designer's rendering bridge. Works for either cover pattern: pass a
code-drawn preset rendered across the whole wrap as `wrap_bg`, or a
background photo (real or a procedural stand-in) — this module only cares
that it already has pixel dimensions `(total_w, total_h)`.

```python
from bubble.cover.full_cover import (
    spec_and_pixels,
    render_code_wrap_background,
    render_image_wrap_background,
    assemble_full_cover,
)

spec, px = spec_and_pixels("kdp/paperback", lang="en", dpi=150)

# "Code" pattern: a named preset rendered across the whole wrap
wrap_bg = render_code_wrap_background("midnight", px, dpi=150)

# or "image" pattern: two independent front/back photos
# wrap_bg = render_image_wrap_background(front_img, back_img, px, spine_color="#101010")

full = assemble_full_cover(
    wrap_bg, px,
    title="My Book Title", subtitle="A Subtitle", author="Author Name",
    publisher="My Press", blurb="Back-cover jacket copy…", lang="en",
)
full.save("full_cover.png")
```

---

## `bubble.cover.code_presets`

Named background presets for the "code" cover pattern (matplotlib, no
photo). Each preset paints only the background layer onto an `Axes` already
set to `xlim(0, 1)` / `ylim(0, 1)`; `cover_front.py` / `cover_back.py` draw
title/subtitle/author/blurb text on top afterward, in the preset's declared
text colors so the copy stays legible against whichever background is
active.

```python
from bubble.cover.code_presets import PRESETS, DEFAULT_PRESET, get_preset

sorted(PRESETS)  # ['corporate-blue', 'low-poly', 'midnight', 'minimal-light']
preset = get_preset("corporate-blue")  # CoverPreset(paint=..., title_color=..., ...)
```

---

## `bubble.cover.print_spec`

Loads dimensions from `bubble/data/cover_print_config.json` (shipped with
the package). Projects can override by passing `config_path` or
keeping a local `cover_print_config.json`.

### Key types

- **`CoverPrintSpec`** — full spread size in inches + dpi (`provider`,
  bleed, panel trim, spine width).
- **`SpreadPixels`** — pixel layout derived from a spec (`back_x0`,
  `spine_x0`, `front_x0`, `panel_w`, `spine_px`, content centers).

### Functions

```python
from pathlib import Path
from bubble.cover.print_spec import (
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

**Provider IDs** use `vendor/binding` form:
`kdp/paperback`, `kdp/paperback_5.5x8.5`, `kdp/paperback_6x9`,
`kdp/paperback_7.5x9.25`, `kdp/paperback_8.5x11`, `kdp/paperback_short`,
`kdp/hardcover`, `ingram/paperback`, `ingram/hardcover`, `lulu/paperback`,
`lulu/hardcover`. Legacy aliases like `kdp_paperback`, `ingram_hardcover`
are accepted.

`get_cover_spec` also takes an optional `spine_width_override_in` — a
vendor cover-calculator spine width that overrides the provider preset's
(spine width tracks page count, so re-derive it whenever page count
changes; this is the same knob as the Cover Designer's
`spine_width_override_in` field).

`bubble-batch` and the Cover Designer use the same provider strings via
`--cover-provider` / the `provider` field.

---

## `bubble.cover.text`

Locale-aware font resolution and text layout shared by the scaffolded cover
scripts — extracted so `cover_back.py` (and any other pattern/preset) can
import it directly instead of loading `cover_front.py` as a sibling file.

```python
from bubble.cover.text import (
    SUPPORTED_LOCALE_TAGS,  # ('en', 'jp', 'sp', 'tc', 'zh')
    load_config,            # reads peanut.config (walks up a couple of dirs)
    first,                  # first(cfg, "title_zh", "title", default="Untitled")
    apply_fonts,            # installs the matplotlib font stack for a lang
    resolve_font_stack,     # font family list for a single plt.text(..., family=...) call
    wrap_text,              # Latin word-wrap / CJK char-wrap, honors explicit "\n"
    output_name,            # output_name("cover_front", "zh") -> "cover_front_zh.pdf"
    lang_from_argv,         # parses --lang=zh or a bare --zh from sys.argv
)

cfg = load_config()
title = first(cfg, "title_zh", "title", default="My Book Title")
apply_fonts(title, lang="zh")
```

---

## `bubble.cover.fonts`

Resolves a font file (Western serif or CJK, by content or by `lang`) and
loads it for PIL at a given point size and dpi.

```python
from bubble.cover.fonts import (
    contains_cjk,
    get_cover_font_path,
    get_locale_font_path,
    get_text_font_path,
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

`get_text_font_path` picks a CJK-capable font by the text's actual content
(via `contains_cjk`), not just a design's declared `lang` — a design left at
`lang="en"` with a Chinese title still needs to render it, not silently draw
tofu boxes.

---

## `bubble.cover.draw`

### Bullets

EB Garamond's Unicode bullet (`U+2022`) renders as a hollow square in PIL.
Use **drawn circular bullets** instead:

```python
from bubble.cover.draw import (
    BULLET_CHAR,
    BULLET_SCALE_DEFAULT,
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

Matplotlib back covers can use `body_text_with_bullets` and
`draw_bullet_dot` on an axes object.

### Layout primitives

```python
from bubble.cover.draw import draw_semiopaque_rounded_rect, y_from_bottom_in_to_px

y = y_from_bottom_in_to_px(3.25, y0, panel_h_px, dpi=300)  # inches from bottom
draw_semiopaque_rounded_rect(img, x, y, w, h, radius_px, alpha=0.75)
```

---

## `bubble.cover.export`

```python
from bubble.cover.export import save_small_jpeg, SMALL_JPEG_LINEAR_SCALE

preview = save_small_jpeg(full_cover_img, Path("out/cover.jpg"), dpi=300)
# → out/cover_small.jpg at ~0.33× linear scale
```

---

## `bubble.cover.image`

Soft darkening of the **lower band** of a cover background (numpy array or
file pipeline):

```python
from bubble.cover.image import dim_image_lower, write_lower_band_bkg

arr = dim_image_lower(arr, frac_lower=0.2, brightness_factor=0.13)
write_lower_band_bkg("cover_front_bkg.png", "cover_front_bkg_v2.png", input_dir=Path("input"))
```

CLI: `python -m bubble.cover.image` also works (see its `main()`).

---

## `bubble.cover.spread`

Full-wrap assembly helpers:

```python
from bubble.cover.spread import (
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

## `bubble.cover.spine`

Spine **bridge** compositing between back and front panels, plus **rotated**
title/subtitle/author text (default 270° CCW):

```python
from bubble.cover.spine import (
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

## `bubble.cover.background`

Low-poly Delaunay triangulation backgrounds (matplotlib → PIL), plus two
plain alternatives with no faceting. Fill modes for the low-poly panel:

- **`LowPolyGradientStyle`** — horizontal two-color blend + jitter (v2 dark
  covers)
- **`LowPolyColormapStyle`** — radial matplotlib colormap (legacy light
  covers, e.g. `viridis_r`)

Optional **`MathWatermarkStyle`** scatters faint `$…$` labels (uses
`math4ai.configure_math_fonts` when available).

```python
from bubble.cover.background import (
    LowPolyGradientStyle,
    MathWatermarkStyle,
    LowPolyColormapStyle,
    render_low_poly_panel,
    render_flat_panel,
    render_smooth_gradient_panel,
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

# No texture at all — a single flat color, or a plain two-stop gradient
flat = render_flat_panel(7.0, 10.0, 300, color=(0.95, 0.94, 0.90))
smooth = render_smooth_gradient_panel(7.0, 10.0, 300, direction="vertical")
```

`cover_front.py` passes book-specific `LOW_POLY_STYLE` and `MATH_WATERMARK`
into this API.

---

## `bubble.cover.barcode`

EAN-13 ISBN barcode generation — a crisp, scannable Bookland EAN-13 barcode
with human-readable numbers and an ISBN header, on a standard white plate
(Amazon KDP / IngramSpark / Bowker conventions). Used by the Cover Designer
when a design's `isbn` field is set.

```python
from bubble.cover.barcode import clean_isbn, generate_isbn_barcode

clean_isbn("978-1-23456-789-0")  # -> "9781234567890" (validates/repairs the check digit)
img = generate_isbn_barcode("978-1-23456-789-0", dpi=300)  # PIL image, or None if unparseable
```

---

## Typical project layout

```
cover/7x10/
  cover_front.py            # copy this repo's templates/cover_front.py in; reads peanut.config
  cover_back.py              # copy this repo's templates/cover_back.py in
  cover_print_config.json   # optional override of bundled print sizes
```

`bubble-build` runs every `*.py` in the cover folder and picks up
`cover_front{,_zh,_tc,_jp,_sp}.pdf` / `cover_back*.pdf` for the build
locale. See **[Covers & templates](covers-templates.md)** for the CLI
(`bubble-batch --cover-provider`) and template mapping, and the
**[Cover Designer](cover-designer.md)** for a browser-based alternative to
editing these scripts by hand.
