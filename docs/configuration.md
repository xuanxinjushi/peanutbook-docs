# Configuration

Bubble reads **`peanut.config`** (JSON) from the project root and merges it with the package default **`peanut.config.default`**. Project values override defaults; unset keys keep default behavior.

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
| `body_font_pt` | number | Body size in pt; CLI `--body-font-pt` overrides |

## Print layout switches

Defaults in `peanut.config.default` favor **legacy / piggy-like** Amazon 7×10 behavior. Enable flags for newer layout features.

| Key | Default | Role |
|-----|---------|------|
| `enable_spot_heading_layout` | `false` | Section title spot/titlesec block in templates |
| `enable_styled_subsection_lua` | `false` | Prepend `styled_subsection.lua` (needs spot layout) |
| `enable_chapter_titlepage_odd_page` | `false` | Force chapter title pages to odd (recto) pages |
| `enable_pod_safe_margins` | `false` | Wider POD margins vs legacy 7×10 geometry |
| `enable_peanut_font_settings` | `false` | Use numeric font keys below vs built-in template defaults |
| `enable_english_body_font_bump` | `false` | Larger English `\normalsize` |
| `enable_chinese_body_font_bump` | `true` | Larger CJK body for `cn`, `tc`, `jp` |

### Font size keys (when `enable_peanut_font_settings` is true)

Examples: `chapter_title_font_size_pt`, `cover_main_title_font_size_pt`, `spot_section_title_font_size_pt`, `chapter_number_on_title_font_size_pt`, … — see `peanut.config.default` for the full list.

## Appendix titles

Per-locale appendix divider strings (optional):

- `appendix_divider_title_en`
- `appendix_divider_title_cn`
- `appendix_divider_title_tc`
- `appendix_divider_title_jp`
- `appendix_divider_title_sp`

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
| `batch_optimize_pdf` | Default `true`; use `--no-optimize-pdf` to override per run |
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
