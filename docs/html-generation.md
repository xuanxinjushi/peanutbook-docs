# HTML generation

Build an online-readable HTML edition of the book alongside the print PDF.

```bash
bubble-render-html
# or
bubble-build --format html
```

## `bubble-render-html` flags

| Flag | Default | Notes |
|------|---------|-------|
| `--lang` | `peanut.config` `lang`, else `en` | `en`, `cn`, `tc`, `jp`, `sp`, or `all` |
| `-o, --output` | `book_html/` (`book_html_{tag}/` for non-`en`) | Or `html_output_dir` |
| `-t, --title` | `book_title` from config | Site/index title |
| `--theme` | `default` | `default`, `dark`, or `minimal` — unknown names fall back to `default` |
| `--css` | none | Custom CSS, copied to `assets/custom.css` |
| `--no-mathjax` | MathJax on | Disables MathJax |
| `--max-chapters` | auto-detect | Ceiling on chapter number to include |
| `--include-appendix` | `auto` | `true`/`false`/`auto` — `auto` includes `chapterx*.md` files if present |
| `--cover` | from config or template default | Cover folder name under `cover/` |
| `--root` | walk up from CWD | Project root override |

`bubble-build --format html` shares `--lang`, `--max-chapters`, `--include-appendix`, and `--cover` with the rest of `bubble-build`, but takes `theme`/`custom_css`/`mathjax` only from `peanut.config` (no dedicated `--theme`/`--css` flags on that command). PDF-only flags (`--optimize-pdf`, `--protect`, watermark options, `--no-cover`) are ignored with a warning when `--format html` is used.

## `peanut.config` keys

None of these ship in `peanut.config.default` — they're optional, code-defaulted keys you add yourself.

| Key | Default | Purpose |
|-----|---------|---------|
| `html_output_dir` | `book_html/` | Output directory override |
| `html_theme` | `default` | Same values as `--theme`; only applied if `--theme` was left at its default |
| `html_custom_css` | none | Path to custom CSS, resolved relative to CWD then project root |
| `html_mathjax` | `true` | Set `false` to disable MathJax |
| `html_site_logo` (falls back to `site_logo`) | empty | Logo shown in the site header |
| `html_purchase_url` (falls back to `purchase_url`) | empty | Purchase button link (e.g. an Amazon page) |
| `html_purchase_label` | `"Buy on Amazon"` | Purchase button text |
| `html_cover_image` | none | Explicit cover image path, bypassing auto-discovery |
| `cover` | derived from `template` | Reused as the HTML cover source when no `--cover`/`html_cover_image` is set |
| `book_title` / `title` / `book_title_en` / `book_title_{tag}` | `"Book"` | Site title per locale — locale-specific keys are checked first |
| `lang` | `en` | Default locale when `--lang` is omitted |

Cover auto-discovery checks, in order, inside the resolved cover folder (and its `out/` subfolder): `3d_front_view.png/.jpg`, `cover_front_v2.png/.jpg`, `cover_front.png/.jpg`, `cover.png/.jpg`.

## Output structure

Single-language build:

```
book_html/
├── index.html                       # book index / TOC, with cover + chapter list
├── preface*.html
├── chapter01.html … chapterNN.html  # one page per chapter markdown file
├── chapterx*.html                   # appendix, if included
└── assets/
    ├── theme.css
    ├── page-reader.js
    ├── cover.<ext>                  # if a cover image was found
    ├── custom.css                   # only if a custom CSS was given
    └── themes/                      # default.css, dark.css, minimal.css, for in-page theme switching
```

Multilingual build (`--lang all`):

```
book_html/
├── index.html          # language picker
├── assets/              # shared theme CSS, cover, JS
├── en/
│   ├── index.html, chapter01.html, …
├── zh/                   # "cn" locale maps to a "zh" output directory
│   └── …
└── compare/zh-en/index.html   # bilingual reader, built separately by bubble-compare-html
```

Each per-language page gets a switcher linking to the same chapter in the other available languages, falling back to that language's index if the chapter doesn't exist there yet.

Each chapter is optionally paginated client-side, with prev/next chapter navigation on every page.

## Themes

Themes are plain CSS files: `default` (light, indigo accent, sans-serif), `dark` (dark background, indigo-ish accent), and `minimal` (light, narrow, serif-forward, amber accent). All three are copied into `assets/themes/` regardless of the active theme.

!!! note "Chapter page limitations"
    The HTML renderer shares markdown parsing with the PDF pipeline but is a separate code path. Equation cross-reference numbering and some LaTeX-specific macros may not render identically to the PDF/EPUB output — check chapters with heavy math or custom LaTeX blocks after an HTML build.
