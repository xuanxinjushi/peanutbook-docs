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

## Chapter styles

| Style | Appearance |
|-------|------------|
| `circle` | Quarter-circle chapter number (default in many configs) |
| `square` | Blue square chapter number |
| `none` | No decoration — typical for KDP/print interior uploads |

```bash
bubble-build --style square
bubble-build --no-cover --style none    # interior-only PDF
```

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

## Business plan narrative layout (bubble-bizplan)

The `bubble-bizplan` workflow compiles a structured business plan Markdown file into an AI4Biz-compliant PDF utilizing Pandoc and LuaLaTeX. It automatically validates the document's structure, enforces academic/corporate formatting, and supports prepending a dynamically-generated cover sheet.

### Required Structure & Validation Rules
To satisfy AI4Biz criteria, the Markdown document must contain specific headings. When running `bubble-bizplan`, it scans the Markdown headings for matches (case-insensitive regex patterns). The required sections and matching keywords are:

1. **`1. The Problem`** (matches `\bproblem\b`)
2. **`2. The AI Solution`** (matches `\bsolution\b`)
3. **`3. AI Technical Feasibility`** (matches `\bfeasibility\b` or `\btechnical feasibility\b`)
    - **`Data Strategy`** (matches `\bdata strategy\b`)
    - **`AI Architecture`** (matches `\barchitecture\b` or `\bai architecture\b`)
    - **`AI Ethics & Safety`** (matches `\bethics\b` or `\bsafety\b`)
4. **`4. Competitive Differentiation`** (matches `\bdifferentiation\b` or `\bcompetitive differentiation\b`)
    - **`Value Proposition Matrix`** (matches `\bmatrix\b` or `\bvalue proposition\b`)
    - **`The "Unfair Advantage"`** (matches `\bunfair advantage\b`)
5. **`5. Business Model`** (matches `\bbusiness model\b` or `\bmodel\b`)

If any of these sections are missing:
* A warning listing the missing sections will be printed.
* If `--strict` is enabled (or `"strict": true` is configured in `peanut-biz.config`), the build will immediately fail with exit code 1.

### Dynamic Cover Page Generation
You can prepend a cover page to your business plan. Under the hood, `bubble-bizplan` checks for a cover sheet in three ways:
1. An explicit PDF path passed via `--cover <path>` (or `"cover_pdf"` in config).
2. A local `cover.pdf` or `cover_front.pdf` in the Markdown directory or working directory.
3. Automatically generating a professional, themed cover sheet using the Python script `generate_bizplan_covers.py` (which uses `matplotlib` to render publication-quality layouts). 

To generate a themed cover on the fly, use `--cover-name <style>`. Available styles:
* **`tech-dark`**: Midnight blue gradient with abstract AI neural network nodes and cyan/violet accents.
* **`minimal-light`**: Clean executive design with off-white paper background and elegant gold/charcoal details.
* **`corporate-blue`**: Corporate navy color-blocking, teal highlights, and a left-aligned grid layout.

Alternatively, you can customize or run `generate_bizplan_covers.py` directly:
```bash
python generate_bizplan_covers.py --title "My Title" --subtitle "My Subtitle" --author "Author Name" --style tech-dark --output cover.pdf
```

### Scaffolding and Templates
You can quickly scaffold a starter business plan markdown template (`bizplan.md`) using either:
```bash
# Via bubble-scaffold
bubble-scaffold --bizplan

# Or via bubble-bizplan initialization
bubble-bizplan --init bizplan.md
```
This generates a skeleton template containing the exact required headings, a starter value proposition matrix table, and prompts for each section.

### Business Plan Configuration (`peanut-biz.config`)
Styling and compilation options can be customized via a `peanut-biz.config` JSON file placed in your project root. The keys and their defaults are:

* `double_spaced` (default: `true`): Enforce double-spacing for body text (tables and footnotes are automatically single-spaced).
* `font_size` (default: `"12pt"`): Set document font size.
* `margin` (default: `"1in"`): Document margins.
* `main_font` (default: `"Times New Roman"`): Main body font. Falls back to *TeX Gyre Termes* or *Nimbus Roman* if not found.
* `lang` (default: `"en"`): Document language.
* `papersize` (default: `"letter"`): Paper size (`letter` or `a4`).
* `optimize_pdf` (default: `false`): Enable PDF size optimization.
* `optimize_pdf_quality` (default: `"printer"`): Ghostscript quality level (`screen`, `ebook`, `printer`, `prepress`).
* `strict` (default: `false`): If `true`, fails compilation if any required narrative sections are missing.
* `cover_pdf` (default: `null`): Path to a pre-built cover PDF.
* `cover_name` (default: `null`): Style name for dynamic cover generation (`tech-dark`, `minimal-light`, `corporate-blue`).

