# Business plans

`bubble-bizplan` compiles a single Markdown file into a PDF business plan — not a multi-chapter book. It targets the "AI for Business" (AI4Biz) narrative format: double-spaced, 12pt Times New Roman, 1in margins, with a 5-page submission guardrail.

```bash
bubble-bizplan --init bizplan.md
bubble-bizplan bizplan.md --cover-name tech-white
```

## CLI flags

| Flag | Default | Notes |
|------|---------|-------|
| `markdown` (positional) | `bizplan.md` in CWD if present | |
| `-o, --output` | same basename, `.pdf` | |
| `--lang` | `en` (or config `lang`) | `en`, `cn`, `tc`, `jp`, `sp` — CJK gets a LuaTeX-ja header automatically |
| `--papersize` | `letter` (or config `papersize`) | `letter` or `a4` |
| `--template` | none | Custom Pandoc LaTeX template |
| `--optimize-pdf` | off | Ghostscript for non-CJK, `qpdf --optimize-images` for CJK |
| `--optimize-pdf-quality` | `printer` | `screen`, `ebook`, `printer`, `prepress` |
| `--strict` | off | Fail the build if required sections are missing |
| `--check-only` | off | Validate structure only, no PDF build |
| `--init` | — | Scaffold the template to the given/default path; errors if the target exists |
| `--cover` | none | Explicit pre-built cover PDF to prepend |
| `--cover-name` | none | `tech-dark`, `tech-white`, `minimal-light`, `corporate-blue` — generates the cover on the fly |
| `--compact` | off | Skips the Pandoc title block — use when the cover already carries title/author/date |
| `--no-cover` | off | Omits the decorative cover page (recommended for AI4Biz submission — max 5 pages) |

A CLI flag overrides `peanut-biz.config`, which overrides the hardcoded default.

## `peanut-biz.config`

JSON file, discovered by walking up from the markdown file's directory (then project root, then CWD, up to 5 parent levels).

| Key | Default | Purpose |
|-----|---------|---------|
| `lang` | `"en"` | Overridden by `--lang` |
| `papersize` | `"letter"` | `letter` or `a4` |
| `optimize_pdf` | `false` | |
| `optimize_pdf_quality` | `"printer"` | |
| `strict` | `false` | |
| `cover_pdf` | `null` | Path to explicit pre-built cover PDF |
| `cover_name` | `null` | One of the four cover styles |
| `include_cover` | `true` | Inverse of `--no-cover` |
| `double_spaced` | `true` | AI4Biz requirement |
| `font_size` | `"12pt"` | |
| `margin` | `"1in"` | |
| `main_font` | `"Times New Roman"` | Falls back to TeX Gyre Termes, then Nimbus Roman, if not installed |
| `spot_heading_min_lines` | `4` | Orphan control for headings |
| `compact` | `false` | Same as `--compact` |
| `tight_layout` | `false` | Tightens heading/table spacing (body stays double-spaced) |
| `table_references` | `true` | Enables table-reference Pandoc filter |
| `table_alternate_rows` | `true` | Alternating row background in tables |
| `cover_title` | falls back to front matter `title` | |

When `--cover-name`/`cover_name` triggers dynamic cover generation, the config can also override per-element cover styling: `cover_font_family`, and color/size/vertical-offset keys for each element (`cover_title_color`, `cover_title_size`, `cover_title_y`, and equivalents for `business_label`, `subtitle`, `website`, `author`, `institution`, `meta_label`, `meta_value`, `date`, plus `cover_logo_y`).

## Required sections

`bubble-bizplan` checks the markdown headings against the AI4Biz structure:

1. **The Problem**
2. **The AI Solution**
3. **AI Technical Feasibility** — with **Data Strategy**, **AI Architecture**, **AI Ethics & Safety** subsections
4. **Competitive Differentiation** — with **Value Proposition Matrix**, **Unfair Advantage** subsections
5. **Business Model**

Matching is case-insensitive and tolerant of numbering/punctuation. With `--strict`, a missing section fails the build; otherwise it's a warning and the build continues.

## YAML front matter

`title`, `author`, `date`, `word_count`, `genre`, `submitted_by`, `submission_date`, `website`, `project_title`, `team_member`, `school`, `country_region`, `contact_email`, `competition_category`.

These feed the Pandoc title block (unless `--compact`) and, when `--cover-name` is set, the generated cover page.

## Cover styles

| Style | Look |
|-------|------|
| `tech-dark` | Modern AI startup — midnight blue & cyan |
| `tech-white` | Same layout, white background |
| `minimal-light` | Executive editorial — clean off-white & gold |
| `corporate-blue` | Structured corporate — navy & teal grid |

The cover is generated separately and merged as page 1 in front of the compiled PDF.

## Page limit

After building, `bubble-bizplan` counts pages and prints a warning if the result exceeds 5 pages (the AI4Biz submission limit) — this does not fail the build, only `--strict` combined with missing sections does.
