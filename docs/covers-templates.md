# Covers and templates

## Page templates

Templates live in the bubble package under `templates/`. Pass `--template` or set `"template"` in `peanut.config`.

| Template | Trim size | Typical use |
|----------|-----------|-------------|
| `amazon_7x10.tpl` | 7×10 in | **Default** — Amazon KDP color |
| `lulu_7x10.tpl` | 7×10 in | Lulu paperback/hardcover |
| `amazon_6x9.tpl` | 6×9 in | Amazon smaller trim |
| `lulu_6x9.tpl` | 6×9 in | Lulu 6×9 |
| `amazon_5.5x8.5.tpl` | 5.5×8.5 in | Mass-market paperback |
| `lulu_5.5x8.5.tpl` | 5.5×8.5 in | Lulu digest |
| `a4_8.5x11.tpl` | 8.5×11 in | US letter / large format |

`bubble-build` and `bubble-convert` default to **`amazon_7x10.tpl`** when no template is set.

## Cover folder selection

Template choice maps to a default cover directory:

| Template | Default cover folder |
|----------|---------------------|
| `lulu_7x10.tpl`, `amazon_7x10.tpl` | `cover/7x10/` |
| `a4_8.5x11.tpl` | `cover/8.5x11/` |

Override with **`--cover`**:

```bash
bubble-build --cover 7x10-packt
bubble-build --cover 7x10
bubble-build --cover 8.5x11
```

## Cover PDF resolution order

For `cover_front.pdf` / `cover_back.pdf`:

1. `cover/{cover_folder}/cover_front.pdf`
2. `cover/cover_front.pdf` (legacy)
3. `cover_front.pdf` in project root

## Regenerating covers

Before using cover PDFs, **`bubble-build` runs Python scripts** in the active cover folder (e.g. `cover_front.py`, `cover_back.py`, or v2 draw scripts) so PDFs match the chosen size and provider.

Cover provider examples (for full-wrap scripts):

```bash
bubble-batch en --cover 7x10 --cover-provider kdp/paperback
bubble-batch all --cover-provider ingram/hardcover --cover-version v2
```

Aliases include `kdp_paperback`, `ingram_hardcover`, `lulu_paperback`, `lulu_hardcover`.

Print dimensions and Python helpers (`bubble.cover_print`, `bubble.cover_draw`, …) are documented in **[Cover rendering API](cover-api.md)**.

### Locale-Aware Covers

For multi-language books, localized cover scripts can be placed alongside default covers:

- `cover/7x10/cover_front_zh.py` → generates `cover_front_zh.pdf`
- `cover/7x10/cover_back_zh.py` → generates `cover_back_zh.pdf`

When building a localized book (e.g. `bubble-build --lang cn`), Peanutbook looks for `cover_front_zh.pdf` (or `cover_front_cn.pdf`) and falls back to `cover_front.pdf` if not found.

Cover scripts use a font stack that leads with universal CJK/Latin families and falls back gracefully to system fonts, avoiding missing-glyph tofu boxes on both English and Chinese builds.

## Chapter styles

| Style | Appearance |
|-------|------------|
| `circle` | Quarter-circle chapter number (default in many configs) |
| `square` | Blue square chapter number |
| `none` | No decoration — typical for KDP/print interior uploads |

```bash
bubble-build --style square
bubble-build --style circle --chapter-opener-size 5
bubble-build --no-cover --style none    # interior-only PDF
```

`chapter_opener_size_cm` in `peanut.config` (default `4`) sets the badge size when CLI omits `--chapter-opener-size`. The numeral font scales with badge size.

## PDF size optimization

```bash
bubble-build --optimize-pdf
bubble-build --optimize-pdf --optimize-pdf-quality prepress   # English: less aggressive GS
```

- **English / Spanish:** Ghostscript `pdfwrite` (requires `gs`)
- **CJK:** `qpdf --optimize-images` (requires `qpdf`; avoids breaking XeLaTeX outlines)

!!! warning "Protection vs size"
    `--protect` rasterizes pages (default 300 DPI), producing large PDFs. For POD uploads prefer `--optimize-pdf` without `--protect`, or lower `--protect-dpi`.

## Proposal / query letter layout

`bubble-proposal` uses `templates/proposal_book_style.tex` — U.S. nonfiction proposal conventions (title page, running header, double-spaced body). YAML front matter in the Markdown can set `title`, `subtitle`, `author`, `runtitle`, `runlastname`, etc.

```bash
bubble-proposal querytracker/proposal.md --lang en --optimize-pdf
```

For business plans (`bubble-bizplan`, `peanut-biz.config`), see **[Business plans](bizplan.md)**.

For academic papers (`bubble-paper`, `templates/paper_style.tex`), see **[Academic papers](paper.md)**.
