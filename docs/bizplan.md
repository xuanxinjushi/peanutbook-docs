# Business plans

Peanutbook includes a separate workflow for **structured business plans**: one Markdown file → PDF with academic/corporate formatting, section validation, and optional cover pages.

This path uses **`peanut-biz.config`** (not `peanut.config`) and the **`bubble-bizplan`** command. It does not use chapter folders, print templates, or book covers.

## Quick start

```bash
bubble-bizplan --init bizplan.md   # scaffold required headings
# edit bizplan.md
bubble-bizplan bizplan.md          # build PDF next to the .md file
```

If you run `bubble-bizplan` with no arguments in a directory that contains `bizplan.md`, that file is compiled automatically.

Alternative scaffold:

```bash
bubble-scaffold --bizplan
```

## Command reference

| Flag | Effect |
|------|--------|
| `markdown` | Input `.md` path (optional; default `bizplan.md` in cwd) |
| `-o`, `--output` | Output PDF path (default: same basename as input) |
| `--init` | Write bundled template to the target path |
| `--check-only` | Validate required sections; do not build PDF |
| `--strict` | Fail (exit 1) if any required section is missing |
| `--cover PATH` | Prepend explicit cover PDF |
| `--cover-name STYLE` | Generate cover on the fly (`tech-dark`, `tech-white`, `minimal-light`, `corporate-blue`) |
| `--lang` | Document language (`en`, `cn`, …) |
| `--papersize` | `letter` (default) or `a4` |
| `--optimize-pdf` | Shrink PDF with Ghostscript after build |
| `--optimize-pdf-quality` | `screen`, `ebook`, `printer`, `prepress` |

Examples:

```bash
bubble-bizplan bizplan.md --cover-name tech-white
bubble-bizplan bizplan.md --strict --check-only
bubble-bizplan bizplan.md --optimize-pdf --optimize-pdf-quality ebook
```

CLI flags override matching keys in `peanut-biz.config`.

## Required structure

`bubble-bizplan` scans Markdown headings for business-plan narrative sections (case-insensitive regex on heading text). Required sections:

| Section | Heading must match |
|---------|-------------------|
| 1. The Problem | `\bproblem\b` |
| 2. The AI Solution | `\bsolution\b` |
| 3. AI Technical Feasibility | `\bfeasibility\b` or `\btechnical feasibility\b` |
| — Data Strategy | `\bdata strategy\b` |
| — AI Architecture | `\barchitecture\b` or `\bai architecture\b` |
| — AI Ethics & Safety | `\bethics\b` or `\bsafety\b` |
| 4. Competitive Differentiation | `\bdifferentiation\b` or `\bcompetitive differentiation\b` |
| — Value Proposition Matrix | `\bmatrix\b` or `\bvalue proposition\b` |
| — The "Unfair Advantage" | `\bunfair advantage\b` |
| 5. Business Model | `\bbusiness model\b` or `\bmodel\b` |

If sections are missing:

- A warning lists what is missing (default).
- With `--strict` or `"strict": true` in config, the build exits with code 1.

After a successful build, a **page-count warning** is printed if the PDF exceeds **5 pages** (submission limit).

## YAML front matter

Optional YAML at the top of the Markdown drives cover metadata:

```yaml
---
title: MockSphere
subtitle: AI-Powered Analytics for SMBs
author: Jane Doe
date: March 2026
institution: Business Plan Submission
---
```

Used when generating a dynamic cover (`--cover-name` or `cover_name` in config).

## Cover pages

`bubble-bizplan` prepends a cover sheet when one is available, in this order:

1. `--cover` / `cover_pdf` in config
2. `cover.pdf` or `cover_front.pdf` next to the Markdown file or in the working directory
3. Dynamic generation via `--cover-name` / `cover_name` (uses bundled `generate_bizplan_covers.py`)

### Cover styles (`--cover-name`)

| Style | Appearance |
|-------|------------|
| `tech-dark` | Midnight blue gradient, abstract waves, light typography |
| `tech-white` | Light gray/off-white gradient, cyan/violet accents |
| `minimal-light` | Off-white paper, gold/bronze waves, double-border frame |
| `corporate-blue` | Navy/teal accents, geometric grid, fluid waves |

All styles show an uppercase **BUSINESS PLAN** label above the title so the title line can stay short (e.g. product name only).

Generate a cover PDF directly (script ships next to `bizplan.py` in the package):

```bash
python generate_bizplan_covers.py \
  --title "My Title" \
  --subtitle "My Subtitle" \
  --author "Author Name" \
  --style tech-white \
  --output cover.pdf
```

When installed from PyPI, locate the script under the `bubble` package directory, or use `bubble-bizplan --cover-name tech-white` instead.

## Configuration (`peanut-biz.config`)

Place **`peanut-biz.config`** (JSON) in the project root. The loader also searches upward from the Markdown directory.

| Key | Default | Role |
|-----|---------|------|
| `double_spaced` | `true` | Double-spaced body (tables/footnotes stay single-spaced) |
| `font_size` | `"12pt"` | Body font size |
| `margin` | `"1in"` | Page margins |
| `main_font` | `"Times New Roman"` | Body font (falls back to TeX Gyre Termes / Nimbus Roman) |
| `lang` | `"en"` | Document language |
| `papersize` | `"letter"` | `letter` or `a4` |
| `optimize_pdf` | `false` | Run Ghostscript shrink pass |
| `optimize_pdf_quality` | `"printer"` | Ghostscript `-dPDFSETTINGS` |
| `strict` | `false` | Fail when required sections are missing |
| `cover_pdf` | `null` | Path to pre-built cover PDF |
| `cover_name` | `null` | Dynamic cover style name |
| `spot_heading_min_lines` | `4` | Minimum lines after a heading (`needspace` guard) |

Example:

```json
{
  "double_spaced": true,
  "font_size": "12pt",
  "margin": "1in",
  "main_font": "Times New Roman",
  "strict": true,
  "cover_name": "tech-white"
}
```

## Formatting defaults

Unless overridden in config, business plans use:

- **12 pt** body text
- **1 inch** margins
- **Double spacing** for narrative body
- **Times New Roman** (or LaTeX serif fallback)
- **Letter** paper (US)

These differ from full-book builds (`peanut.config` + print templates).

## Python API

```python
from pathlib import Path
from bubble.bizplan import build_bizplan_pdf, validate_markdown_sections

missing = validate_markdown_sections(Path("bizplan.md"))
if missing:
    print("Missing:", missing)

code = build_bizplan_pdf(
    Path("bizplan.md"),
    Path("bizplan.pdf"),
    cover_name="tech-white",
    strict=True,
)
```

`build_bizplan_pdf` returns `0` on success, non-zero on failure. CLI equivalent: `bubble-bizplan`.

## See also

- [Build & convert — `bubble-bizplan`](commands/build-convert.md#bubble-bizplan) — short CLI summary
- [Covers & templates](covers-templates.md) — book print templates and proposal PDFs
