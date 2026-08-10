# Configuration

Peanutbook reads **`peanut.config`** (JSON) from the project root and merges it with the package default **`peanut.config.default`**. Optional **[Theme](theme.md)** (`peanut.theme.json` or a `theme` block) controls colors and chapter opener styling without LaTeX.

Project values override defaults; unset keys keep default behavior.

## Minimal example

```json
{
  "lang": "en",
  "chapter_style": "circle",
  "template": "amazon_7x10.tpl",
  "book_title": "Your Book Title",
  "conda_env": "your_env_name",
  "include_math": true,
  "include_numpy": false,
  "include_torch": false
}
```

## Core keys

| Key | Values | Role |
|-----|--------|------|
| `lang` | `en`, `cn`, `tc`, `jp`, `sp` | Default locale when CLI omits `--lang` |
| `chapter_style` / `style` | `circle`, `square`, `none` | Chapter decoration; CLI `--style` overrides |
| `template` | e.g. `amazon_7x10.tpl` | Pandoc/LaTeX page template |
| `book_title` | string | Title in headers, TOC, covers |
| `conda_env` | string | Conda env for running `img/*.py` scripts |
| `include_math` | bool | Math packages in LaTeX header |
| `include_numpy` | bool | NumPy icon in code blocks |
| `include_torch` | bool | PyTorch icon in code blocks |
| `page_number_side` | e.g. `even-left` | Running page number placement |
| `main_font` | font name | Body font (Latin locales); CLI `--main-font` overrides |
| `chapter_title_font` | font name | Chapter opener title only (Latin); body stays on `main_font` |
| `body_font_pt` | number | Body size in pt; CLI `--body-font-pt` overrides |

## Theme

See **[Theme](theme.md)** for `peanut.theme.json`, colors, `chapter_opener`, and `quote_style`.

## Print layout switches

Defaults in `peanut.config.default` favor **legacy / piggy-like** Amazon 7×10 behavior. Enable flags for newer layout features.

| Key | Default | Role |
|-----|---------|------|
| `enable_spot_heading_layout` | `false` | Section title spot/titlesec block in templates |
| `enable_styled_subsection_lua` | `false` | Prepend `styled_subsection.lua` (needs spot layout) |
| `enable_chapter_titlepage_odd_page` | `false` | Force chapter title pages and part openers to odd (recto) pages |
| `enable_pod_safe_margins` | `false` | Wider POD margins vs legacy 7×10 geometry |
| `enable_peanut_font_settings` | `false` | Use numeric font keys below vs built-in template defaults |
| `enable_english_body_font_bump` | `false` | Larger English `\normalsize` |
| `enable_chinese_body_font_bump` | `true` | Larger CJK body for `cn`, `tc`, `jp` |

Spot heading spacing (when `enable_spot_heading_layout` is true):

| Key | Default | Role |
|-----|---------|------|
| `spot_heading_vspace` | template-dependent | Vertical space before a `##` spot heading |
| `spot_first_section_extra_above` | template-dependent | Extra skip before the first `##` after a chapter title page (body chapters; often negative) |
| `spot_matter_first_section_extra_above` | `0.35em` | Extra skip before the first `##` after a plain `#` (Copyright / front matter) |
| `spot_heading_rule_skip` | `0.03em` (Lulu) / `0.1em` (Amazon/A4) | Gap between title text and the rule under it; negative values pull the title toward the line |
| `matter_chapter_after_skip` | `0.3em` | Space after unnumbered `\chapter*` titles (Foreword, Endorsements, Copyright, …) |

### Font size keys (when `enable_peanut_font_settings` is true)

Examples: `chapter_title_font_size_pt`, `cover_main_title_font_size_pt`, `spot_section_title_font_size_pt`, `chapter_number_on_title_font_size_pt`, … — see `peanut.config.default` for the full list.

## Appendix titles

Per-locale appendix divider strings (optional):

- `appendix_divider_title_en`
- `appendix_divider_title_cn`
- `appendix_divider_title_tc`
- `appendix_divider_title_jp`
- `appendix_divider_title_sp`

## Code blocks

| Key | Default | Role |
|-----|---------|------|
| `bash_wrap_columns` | `76` | Terminal `bash` / `sh` / `shell`: wrap long lines at spaces with `\`; `null` or `0` disables |
| `code_font` | `null` | Optional font family for code blocks (e.g. `"JetBrains Mono"`); `null` uses `\ttfamily` |
| `code_font_size` | `small` | LaTeX size command for code blocks (`\small`, `\footnotesize`, `normalsize`, etc.) |
| `code_block_font_size` | `small` | Deprecated alias for `code_font_size` |
| `caption_font_size` | `small` | Caption font: named size or absolute (`9`, `9pt`). Absolute uses `\DeclareCaptionFont` |
| `caption_font_baselineskip_pt` | `null` | Leading for absolute caption size (default `1.2 ×` size) |
| `wrap_figure_float` | `true` | Floating wrapfig (`R`/`L`) |
| `wrap_needspace_lines` | `12` | `\Needspace*` before wrapfigure |
| `enable_wrap_preflight` | `false` | Opt-in `wrap_preflight.lua`: auto `lines` + `\WFclear` before nearby display math (can shrink short wrap windows) |
| `code_line_numbers` | `null` | When `true`, enable code line numbers (see `peanut.config.default`) |

`bubble-convert` / `bubble-build` pass merged values to Lua filters via `BUBBLE_BASH_WRAP_COLUMNS`, `BUBBLE_CODE_FONT_USE`, `BUBBLE_CODE_FONT_SIZE`, `BUBBLE_WRAP_FIGURE_FLOAT`, and `BUBBLE_WRAP_NEEDSPACE_LINES`.

## DOCX / EPUB

| Key | Role |
|-----|------|
| `docx_footer_text` | Header/footer text in Word export |
| `docx_footer_text_position` | Default `top-right` |
| `docx_page_number` | Default `true` |
| `docx_page_number_position` | Default `bottom-right` |

Place **`reference.docx`** in the project root (or `margins/reference_submission.docx`) for Word styling. Place **`epub.css`** in the project root to override the bundled EPUB stylesheet. EPUB cover: `cover_front.png` or `cover_front.jpg` in the active cover folder.

## Batch release keys (`bubble-batch`)

| Key | Role |
|-----|------|
| `batch_default_langs` | JSON array, e.g. `["cn", "tc", "en"]`; used when LANG is omitted or `all` |
| `batch_book_ads` | Footer text for protected per-chapter PDFs (`--ads`) |
| `batch_output_dir` | Collect directory (default `books`) |
| `batch_cover_style` | Cover build style: `circle`, `square`, `none` |
| `batch_chapter_style` | Style for `--chapters` per-chapter PDFs |
| `batch_optimize_pdf` | Default `false`; use `--optimize-pdf` to enable (or `--no-optimize-pdf` to force off) |
| `batch_optimize_pdf_quality` | `screen`, `ebook`, `printer`, `prepress` (default `ebook`) |

Example:

```json
{
  "batch_default_langs": ["cn", "tc", "en"],
  "batch_book_ads": "My Book Title — Author Name",
  "batch_chapter_style": "square"
}
```

## CLI vs config

Command-line flags always override `peanut.config` for the same setting (e.g. `--lang`, `--style`, `--template`, `--main-font`).

Wrap + display math (`wrap_preflight.lua`, **off by default**): set `enable_wrap_preflight: true` to estimate `lines` from following prose and insert `\WFclear` before a nearby display equation. Can make short wrap windows look like non-wrap. Opt out of clear per image with `{.no-wfclear}`. Does **not** auto-change `{.wrap}` to `{.block}`.
