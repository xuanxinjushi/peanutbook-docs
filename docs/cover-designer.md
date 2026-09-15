# Cover Designer (web app)

A small Django app for designing book covers (front, back, and a full wrap
cover with a real spine/ridge) in a browser. It's a thin UI over the
[`bubble.cover`](cover-api.md) package used everywhere else in the project —
no cover-rendering logic lives in the web app itself, only the web glue.

!!! note "Not the peanutbook.com product"
    This is a self-contained local dev tool (SQLite, no auth, no
    Celery/Redis) meant to be run on your own machine while designing a
    cover. It is not the hosted, multi-user `peanutbook.com` product.

## Running it

```bash
cd web
conda activate usao   # or any env with `pip install -e ..` (peanutbook) done
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Then open <http://127.0.0.1:8000/> in your browser. The server runs with
`DEBUG = True` by default, which enables auto-reload, browser traceback
pages, and local serving of `/media/` (generated renders and uploads).

Common options:

```bash
# Reachable from other devices on your local network
python manage.py runserver 0.0.0.0:8000

# Disable the auto-reloader (recommended when setting breakpoints)
python manage.py runserver --noreload

# Explicitly toggle DEBUG
DJANGO_DEBUG=True python manage.py runserver
```

If port 8000 is already in use:

```bash
fuser -k 8000/tcp
# or: kill -9 $(lsof -t -i:8000)
# or just run on another port: python manage.py runserver 8001
```

## What it does

Each **design** is one `CoverDesign` row: a full set of cover parameters plus
its last-rendered front/back/full-wrap images. From the design list you can
create, edit, **clone** (duplicates all fields and uploaded/rendered images
as independent copies), regenerate, or delete a design.

Two background patterns, chosen per design:

- **Code-drawn** — pick one of `bubble.cover.code_presets`' named presets:
  `midnight` (default), `low-poly`, `minimal-light`, `corporate-blue`. No
  image upload needed.
- **Background image** — upload your own photo/art for the front and back
  panels independently. Without an upload, pick one of the bundled gallery
  presets, or leave both unset and a procedurally generated placeholder is
  used so the tool still works end to end.

Either pattern renders three images: **front cover**, **back cover**, and a
**full wrap cover** with a fogged spine carrying the rotated title/author and
optional logo uploads.

On the edit page, the **⚡ Render & Preview** button re-renders in place over
AJAX (no page reload) and updates the three preview panes; a separate
"save without rendering" path exists for editing fields quickly without
paying the render cost each time. Each preview image has its own **⬇ PDF /
PNG / JPG** download buttons (re-encoded on download — the stored render is
always PNG) and a **fullscreen (+)** button that opens it via the browser's
Fullscreen API.

### Where the rendering actually lives

`coverdesigner/rendering.py` is a thin bridge from a `CoverDesign` instance
to:

- `bubble.cover.render` — parameterized front/back "code" pattern drawing,
  shared with `templates/cover_front.py` / `cover_back.py`
- `bubble.cover.full_cover` — panel geometry, background-image fitting,
  spine fogging, and full-cover assembly, shared with
  `tests/test_cover_image_pattern_gallery.py`

If you want to change how covers look, change those modules, not the web
app — every other consumer (scaffolded templates, gallery tests) picks up
the change too.

## Field reference

### Print vendor, locale, spine width

| Field | Notes |
|---|---|
| `provider` | Print vendor/binding profile (trim size, bleed, spine width). One of `kdp/paperback`, `kdp/paperback_5.5x8.5`, `kdp/paperback_6x9`, `kdp/paperback_7.5x9.25`, `kdp/paperback_8.5x11`, `kdp/paperback_short`, `kdp/hardcover`, `ingram/paperback`, `ingram/hardcover`, `lulu/paperback`, `lulu/hardcover`. Same provider strings as `--cover-provider` — see [Covers & templates](covers-templates.md). |
| `spine_width_override_in` | Spine width in inches from your print vendor's cover calculator, overriding the provider preset's spine width. **Re-check this whenever the page count changes** — spine width tracks page count. Blank = use the provider preset. |
| `lang` | One of `en`, `jp`, `sp`, `tc`, `zh` — see [Multi-language](multi-language.md). |

### Shared typography knobs

Most text elements (title, edition, subtitle, author, foreword, publisher,
back title, back subtitle, website, blurb, spine title, spine subtitle,
spine author) expose the same family of fields, prefixed with the element's
name — e.g. `title_font_family`, `title_font_size_pt`, `title_align`, …
Every knob has an "auto" value (blank, or a listed default) that reproduces
the original hardcoded look, so an untouched design still renders correctly:

| Suffix | Meaning |
|---|---|
| `_font_family` | Blank = default serif. Choices: `sans`, `sans-bold`, `sans-light`, `slab` (slab serif), `libertine` (literary serif), `cabin` (geometric sans), `rounded`, `mono`, `impact` (bold display), `kai` (Kaiti/calligraphic), `wqy-hei` (WenQuanYi Hei, CJK). |
| `_font_size_pt` | Blank = automatic default size. Title is capped at 127pt. |
| `_align` | `center` / `left` / `right` (back-cover text defaults to `left`; front-cover text defaults to `center`). |
| `_vertical_pct` | Vertical position within the panel: 0 = top edge, 100 = bottom edge. Not every element has this — spine title always flows under the logo/top margin instead. |
| `_color` | Hex color. Blank = the pattern's default color. |
| `_effect` | `none` / `shadow` / `glow` behind the text. Spine text defaults to `shadow` (it always drew a hardcoded drop shadow before this field existed); title/author/etc. default to `none`. |

Elements and which optional knobs they carry:

| Element | Field prefix | Extra notes |
|---|---|---|
| Title | `title` | Front-cover main title. |
| Edition line | `edition` | Optional, e.g. "First Edition", drawn between title and subtitle. Blank = not shown. |
| Subtitle | `subtitle` | |
| Author | `author` | Plus optional `author_stamp` (below). |
| Foreword | `foreword` | Optional, e.g. "Foreword by Jane Doe, Ph.D." Blank = not shown (unlike title/author, meant to often be empty). |
| Publisher | `publisher` | Shown on front and back previews and the assembled full cover. |
| Back title | `back_title` | Overrides front title on the back cover. Blank = reuses front title. |
| Back subtitle | `back_subtitle` | Overrides front subtitle on the back cover. Blank = reuses front subtitle. |
| Website | `website` | URL shown on the back cover. `website_align` blank = matches publisher's alignment; `website_font_family` blank = matches publisher's font. |
| Blurb | `blurb` | Back-cover jacket copy — see [Blurb](#blurb) below. |
| Spine title | `spine_title` | Blank = reuses front title. |
| Spine subtitle | `spine_subtitle` | Blank = none. |
| Spine author | *(no separate text field — reuses `author`)* | Has its own `spine_author_font_size_pt`, `spine_author_vertical_pct`, `spine_author_color`, `spine_author_effect`. |

### Author stamp

`author_stamp` is an optional personal seal/chop image, drawn immediately to
the left of the author name on the front cover. Upload-only — there's no
bundled default, since a stamp is inherently personal. `author_stamp_scale_pct`
sizes it relative to the author text's own line height (not an absolute
pixel size), so it stays in proportion if the author font size changes.

### ISBN barcode

`isbn` (e.g. `978-1-23456-789-0`) generates an EAN-13 barcode on the back
cover when set. `isbn_align` places it `right` (default), `left`, or
`center`.

### Blurb

`blurb` is the back-cover jacket-copy paragraph. It shares the typography
knobs above (`blurb_font_family`, `blurb_font_size_pt`, `blurb_align` —
default `left`, since a paragraph reads better ragged-right than centered —
`blurb_color`), plus:

- `blurb_vertical_pct` — where the back-cover content block *starts*. Back
  title, back subtitle, and (unless overridden) the blurb all flow downward
  from here in sequence.
- `blurb_body_vertical_pct` — an independent vertical position for just the
  blurb paragraph, instead of flowing after the back title/subtitle. Blank =
  flows normally.
- `blurb_bg_opacity_pct` / `blurb_bg_color` — a tinted panel drawn behind
  just the blurb text (0–100% opacity, blank color = black) to boost
  contrast against a busy background image. Only the blurb's own footprint
  is covered.

**Decorative dividers**: typing one of the following marker names on its own
line inside the blurb pastes the matching decorative divider image there
instead of drawing it as text — the same marker names used for HBAR
ornaments in the book body (see
[Markdown syntax extensions](markdown-syntax-extensions.md)):

`HBAR1_CLOUD` / `HBAR_CLOUD`, `HBAR_TOP`, `HBAR_BOT`,
`HBAR_CENTER_CLOUD_RED`, `HBAR_CENTER_FLOWER_RED`,
`HBAR_CENTER_DRAGONFLY_RED`, `HBAR_CENTER_LOTUS_RED`,
`HBAR_RIGHT_CLOUD_RED`, `HBAR_RIGHT_CLOUD_BLUE`, `HBAR_SMALL_CENTER`.

This is an exact-match lookup, not a Markdown parser.

### Background image pattern

Only relevant when `pattern = image`. Front and back are two independent
photos — a real print wrap cover isn't one continuous panorama; the spine
between them is synthesized, not photographed.

For each side (`_front` / `_back` suffix):

- `background_image_*` — an upload always wins over the preset below.
- `background_preset_*` — used when no image is uploaded; one of the
  bundled gallery photos, or blank for a procedural placeholder.
- `image_scale_pct_*`, `image_offset_x_pct_*`, `image_offset_y_pct_*`,
  `image_rotation_deg_*` — placement; the photo no longer has to fill the
  whole panel. Defaults (100/0/0/0) reproduce the old always-cover-fit
  behavior exactly.
- `background_color_*` — shows through wherever the photo doesn't cover.
  Blank = neutral dark default.
- `dim_start_pct_*` / `dim_brightness_pct_*` — the bottom-darkening
  gradient for text legibility over a photo (0 = darkening starts at the
  top edge / 0 = fully black at the darkest point; 100 = no darkening).
- `spine_background_color` — the gap between front/back panels before spine
  fogging blurs/tints over it; only shows through directly if neither
  panel's photo reaches the spine edge.

### Logos

- `author_logo`, `press_logo` — spine logos, for either pattern. An upload
  always wins over `author_logo_choice` / `press_logo_choice`
  (`default` bundled logo, or `none`). `*_scale_pct` sizes relative to the
  default fit.
- `back_logo` — back-cover logo. An upload always wins; otherwise
  `back_logo_choice` picks `press` (reuses the press logo), `author`
  (reuses the author logo), or `none`.

## Known limitations (v1)

- No accounts; every design is visible to whoever can reach the server.
- Local disk storage only (`media/`), not object storage.
- Re-rendering is synchronous (a couple of seconds per design) — fine for
  one user clicking Save, not for concurrent multi-user load.

See also **[Covers & templates](covers-templates.md)** for the CLI-driven
cover pipeline (`bubble-build`, `bubble-batch --cover-provider`, template
mapping) and **[Cover rendering API](cover-api.md)** for the underlying
Python helpers.
