# Configuration

Peanutbook reads **`peanut.config`** (JSON) from the project root and merges it with the package default **`peanut.config.default`**. Optional **[Theme](theme.md)** (`peanut.theme.json` or a `theme` block) controls colors and chapter opener styling without LaTeX.

Project values override defaults; unset keys keep default behavior.

## Minimal example

```json
{
  "lang": "en",
  "chapter_style": "circle",
  "chapter_opener_size_cm": 4,
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
| `chapter_opener_size_cm` | number (cm) | Opener badge size: square side or circle radius; chapter numeral font scales with it (default `4`). CLI `--chapter-opener-size` overrides. Legacy key: `square_size_cm` |
| `template` | e.g. `amazon_7x10.tpl` | Pandoc/LaTeX page template |
| `book_title` | string | Title in headers, TOC, covers |
| `conda_env` | string | Conda env for running `img/*.py` scripts |
| `include_math` | bool | Math packages in LaTeX header |
| `include_numpy` | bool | NumPy icon in code blocks |
| `include_torch` | bool | PyTorch icon in code blocks |
| `page_number_side` | e.g. `even-left` | Running page number placement |
| `main_font` | font name | Body font (Latin locales); CLI `--main-font` overrides |
| `chapter_title_font` | font name | Chapter opener title only; body stays on `main_font` |
| `body_font_pt` | number | Body size in pt; CLI `--body-font-pt` overrides |

### English body font comparison

The packaged default is **Latin Modern Roman** (Computer Modern–style). It is fine for pure LaTeX math books, but `0`/`O` and `1`/`I` can look alike in body text. Set `main_font` in `peanut.config` or pass `--main-font` on the CLI.

| Font | Industry use | 0/O, 1/I clarity | Notes |
|------|----------------|------------------|--------|
| **STIX Two Text** | STEM journals, textbooks | Good | Strong choice for math / AI books |
| **TeX Gyre Termes** | General books, KDP | OK–good | Classic Times-like book face |
| **IBM Plex Serif** | Tech / corporate | Strong | Modern, very readable |
| **Source Serif 4** | Long-form reading | Strong | Adobe open font |
| EB Garamond | Literary / elegant | Moderate | Attractive; less ideal for dense math |

Example (body font + chapter opener title):

```json
{
  "enable_peanut_font_settings": true,
  "main_font": "STIX Two Text",
  "chapter_title_font": "Impact",
  "chapter_title_font_size_pt": 24,
  "chapter_title_font_baselineskip_pt": 30
}
```

`chapter_title_font` works without `enable_peanut_font_settings`. **Size** keys (`chapter_title_font_size_pt`, `chapter_title_font_baselineskip_pt`) apply only when `enable_peanut_font_settings` is `true`; otherwise templates use built-in defaults (`20` / `26` pt).

In **`peanut.theme.json`**, the same sizes use shorter names: `chapter_title_size_pt` and `chapter_title_leading_pt` (mapped to the `chapter_title_font_*` keys above). See **[Theme](theme.md)**.

| Key | Default | Role |
|-----|---------|------|
| `enable_peanut_font_settings` | `false` | When `true`, numeric font size keys below override template defaults |
| `chapter_title_font_size_pt` | `20` | Chapter opener title font size (pt) |
| `chapter_title_font_baselineskip_pt` | `26` | Chapter opener title line spacing (pt) |

For code blocks, body `main_font` does not change monospace. Use **`code_font`** and **`code_font_size`** in `peanut.config` (see [Code blocks](#code-blocks) below). When `code_font` is `null`, LaTeX uses `\ttfamily` (standard monospace). Set `code_font` to an installed mono font name (e.g. `"JetBrains Mono"`) for a custom face.

## Theme

See **[Theme](theme.md)** for `peanut.theme.json`, colors, `chapter_opener`, `chapter_opener_size_cm`, and `quote_style`.

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

### Font size keys (when `enable_peanut_font_settings` is true)

When `"enable_peanut_font_settings": true` is configured, you can fine-tune individual element font sizes:

#### Section Heading Settings
- `spot_section_number_font_size_pt` (default `13`): Font size of section numbers (e.g. **2.1**).
- `spot_section_number_font_baselineskip_pt` (default `18`): Line height/baseline skip of section numbers.
- `spot_section_title_font_size_pt` (default `20`): Font size of section titles (e.g. **Computational Power**).
- `spot_section_title_font_baselineskip_pt` (default `24`): Line height/baseline skip of section titles.
- `spot_heading_min_lines` (default `4`): The minimum number of lines of text (baselineskip) that must fit at the bottom of the page before printing a section heading. Under the hood, this uses the LaTeX `needspace` package and is automatically enforced in all `.tpl` templates for both standard `titlesec` formats and custom `\spotheading` / `\spotheadingunnumbered` macros (which are active when `enable_styled_subsection_lua` is `true`). If less space is available, it automatically moves the heading to the next page, preventing orphaned headings at the bottom of pages.
- `spot_heading_vspace` (default `"0.25em"` for `a4_8.5x11.tpl`, `"1.85em"` for others): The vertical space inserted before each `##` heading.
- `spot_first_section_extra_above` (default `"-0.5em"` for `a4_8.5x11.tpl`, `"-2.85em"` for others): The extra vertical space inserted before the first `##` heading of each chapter. Typically configured as a negative value to pull the heading up and cancel out the `spot_heading_vspace` at the top of a page.

#### Code Block and Table Settings
- `code_font` (default `null`): Optional font family for code blocks (e.g. `"JetBrains Mono"`, `"Fira Code"`). `null` uses LaTeX `\ttfamily` (standard monospace). The font must be installed for the PDF engine (LuaLaTeX/XeLaTeX).
- `code_font_size` (default `"small"`): LaTeX size command for code blocks — without the backslash, e.g. `"small"`, `"footnotesize"`, `"normalsize"`, `"scriptsize"`.
- `code_block_font_size` (default `"small"`): Deprecated alias for `code_font_size`.
- `caption_font_size` (default `"small"`): Caption font for figures and tables. Named sizes (`tiny`, `scriptsize`, `footnotesize`, `small`, `normalsize`, …) or absolute point sizes (`9`, `9pt`, `9.5`). Absolute sizes are applied via `\DeclareCaptionFont` + `\fontsize`.
- `caption_font_baselineskip_pt` (default `null`): Line leading when `caption_font_size` is absolute; default is `1.2 ×` the size.
- `wrap_figure_float` (default `true`): Prefer floating wrapfig placement (`R`/`L` instead of exact `r`/`l`) so wrap figures can move rather than hang into the bottom margin. Override per image with `{float=false}` or `{.nofloat}`.
- `wrap_needspace_lines` (default `12`): Before each wrapfigure, emit `\Needspace*{N\baselineskip}` so LaTeX starts a new page when too little room remains. Set `0` or `null` to disable.
- Wrap + display math: Wrap + display math (`wrap_preflight.lua`): if `lines` is unset, estimate it from following prose; insert `\WFclear` before a nearby display equation so it does not overlap the figure. Opt out of clear with `{.no-wfclear}`. Does **not** auto-change `{.wrap}` to `{.block}`.
- `bash_wrap_columns` (default `76`): For default terminal `bash` / `sh` / `shell` blocks, wrap long lines at spaces with a trailing `\`; continuation lines are indented two spaces. Applies to single-line commands and to individual long lines inside multi-line scripts (`#` comment lines are not wrapped). Set `null` or `0` to disable. See [Terminal style](markdown-syntax-extensions.md#terminal-style-default-for-bash-sh-shell).
- `table_font_size` (default `"normalsize"`): Sets the font size of tables globally. Supported values are standard LaTeX font sizing commands (without backslash), e.g. `"normalsize"`, `"small"`, `"footnotesize"`, `"scriptsize"`.
- `code_annotation_style` (default `null`): Sets the global style for code line number annotations and explanations. Supported values:
  - `"circle"`: Force circled annotations.
  - `"bar"` or `"box"`: Force boxed/bar annotations.
  - `null`: Determine style dynamically per-code-block (uses circle style unless `#LINEBAR` is specified in the code block).
- `code_line_numbers` (default `null`): Sets the global line number behavior for code blocks:
  - `true`: Globally enable line numbers for all code blocks (can be disabled locally via `NOLINENUM`).
  - `false` / `null`: Keep default behavior (line numbers are only enabled when followed by `CODE_EXPLAIN_START` or when `#LINENUM` is specified locally).
#### Other Font Keys
See `peanut.config.default` for the full list of other keys (such as `chapter_title_font_size_pt`, `cover_main_title_font_size_pt`, `chapter_number_on_title_font_size_pt`, `chapter_quote_font_size_pt`, etc.).

## Appendix titles

Per-locale appendix divider strings (optional):

- `appendix_divider_title_en`
- `appendix_divider_title_cn`
- `appendix_divider_title_tc`
- `appendix_divider_title_jp`
- `appendix_divider_title_sp`

## Code blocks

These keys apply to PDF builds without requiring `enable_peanut_font_settings`.

| Key | Default | Role |
|-----|---------|------|
| `bash_wrap_columns` | `76` | Terminal `bash` / `sh` / `shell`: wrap long lines at spaces with `\`; `null` or `0` disables |
| `code_font` | `null` | Optional font family for code blocks (e.g. `"JetBrains Mono"`); `null` uses `\ttfamily` |
| `code_font_size` | `small` | LaTeX size command for code blocks (`\small`, `\footnotesize`, `normalsize`, etc.) |
| `code_block_font_size` | `small` | Deprecated alias for `code_font_size` |
| `caption_font_size` | `small` | Named size or absolute pt (`9`, `9pt`) for figure/table captions |
| `caption_font_baselineskip_pt` | `null` | Leading for absolute caption size (default `1.2 ×` size) |
| `wrap_figure_float` | `true` | Floating wrapfig (`R`/`L`); per-image `{float=false}` / `{.nofloat}` |
| `wrap_needspace_lines` | `12` | `\Needspace*` lines before wrapfigure; `0` disables |
| `code_line_numbers` | `null` | When `true`, enable code line numbers (see `peanut.config.default`) |

`bubble-convert` / `bubble-build` pass merged values to Lua filters via `BUBBLE_BASH_WRAP_COLUMNS`, `BUBBLE_CODE_FONT_USE`, and `BUBBLE_CODE_FONT_SIZE`.

Example — smaller code with JetBrains Mono:

```json
{
  "code_font": "JetBrains Mono",
  "code_font_size": "footnotesize",
  "bash_wrap_columns": 76
}
```

Example — default monospace, only change size:

```json
{
  "code_font": null,
  "code_font_size": "footnotesize"
}
```

## DOCX / EPUB

| Key | Role |
|-----|------|
| `docx_footer_text` | Header/footer text in Word export |
| `docx_footer_text_position` | Default `top-right` |
| `docx_page_number` | Default `true` |
| `docx_page_number_position` | Default `bottom-right` |

Place **`reference.docx`** in the project root (or `margins/reference_submission.docx`) for Word styling. Place **`epub.css`** in the project root to override the bundled EPUB stylesheet. EPUB cover: `cover_front.png` or `cover_front.jpg` in the active cover folder.

## HTML book site

| Key | Role |
|-----|------|
| `html_output_dir` | Custom output directory (default `book_html/` or `book_html_{tag}/`) |
| `html_theme` | `default`, `dark`, or `minimal` |
| `html_custom_css` | Path to extra CSS copied to `assets/custom.css` |
| `html_mathjax` | Set `false` to disable MathJax (default `true`) |
| `html_site_logo` | Logo URL or path for site header |
| `html_purchase_url` | Purchase link (e.g. Amazon product page) |
| `html_purchase_label` | Header button text (default `Buy on Amazon`) |
| `html_cover_image` | Override home-page cover image |

See **[HTML generation](html-generation.md)** for the full guide (`bubble-render-html`, `bubble-build --format html`, output layout, themes).

Example:

```json
{
  "html_site_logo": "https://example.org/static/logo.png",
  "html_purchase_url": "https://www.amazon.com/dp/XXXXXXXXXX",
  "html_purchase_label": "Buy on Amazon"
}
```

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

Command-line flags always override `peanut.config` for the same setting (e.g. `--lang`, `--style`, `--template`, `--main-font`, `--chapter-opener-size`).
