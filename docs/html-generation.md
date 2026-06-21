# HTML book generation

Peanutbook can export the same chapter Markdown as a **static HTML book site** — a local or hostable mini-website with a home page, per-chapter pages, MathJax, and in-chapter navigation. No Pandoc or LaTeX is required for HTML output.

## Commands

### `bubble-render-html`

Dedicated HTML build (recommended during development):

```bash
bubble-render-html
bubble-render-html --lang cn
bubble-render-html --lang cn -t "云层之上"
bubble-render-html -o dist/html
bubble-render-html --theme default --no-mathjax
bubble-render-html --max-chapters 21
bubble-render-html --cover 7x10
```

### `bubble-build --format html`

Same pipeline, integrated with the main build command:

```bash
bubble-build --format html
bubble-build --format html --lang cn
bubble-build --format html --max-chapters 21
```

Print-only flags (`--optimize-pdf`, `--protect`, watermarks, `--no-cover`) are ignored for HTML builds.

## Output layout

| Locale | Default output directory |
|--------|--------------------------|
| `en` | `book_html/` |
| `cn` | `book_html_zh/` |
| `tc` | `book_html_tc/` |
| `jp` | `book_html_jp/` |
| `sp` | `book_html_sp/` |

Override with `-o` / `--output` or `html_output_dir` in `peanut.config`.

Typical contents:

```
book_html/
├── index.html              # home page (cover, TOC, Start reading)
├── preface.html
├── chapter01.html
├── chapter02.html
├── …
├── chapterx.html           # appendix (when included)
└── assets/
    ├── theme.css
    ├── page-reader.js
    ├── cover.png           # from cover/7x10/ (prefers 3d_front_view.png)
    └── custom.css          # optional, from html_custom_css
```

Open `index.html` in a browser, or serve the folder with any static file server.

## Configuration

Add optional keys to `peanut.config`:

```json
{
  "book_title": "Mathematics for AI and Machine Learning",
  "html_output_dir": null,
  "html_theme": "default",
  "html_custom_css": null,
  "html_mathjax": true,
  "html_site_logo": "https://example.org/logo.png",
  "html_purchase_url": "https://www.amazon.com/dp/XXXXXXXXXX",
  "html_purchase_label": "Buy on Amazon",
  "html_cover_image": null
}
```

| Key | Role |
|-----|------|
| `html_output_dir` | Custom output path (relative to project root or absolute) |
| `html_theme` | CSS theme: `default`, `dark`, or `minimal` |
| `html_custom_css` | Extra stylesheet copied to `assets/custom.css` |
| `html_mathjax` | Set `false` to disable MathJax |
| `html_site_logo` | Logo URL or path for the site header |
| `html_purchase_url` | External purchase link (shown as a highlighted button in the header) |
| `html_purchase_label` | Button text (default: `Buy on Amazon`) |
| `html_cover_image` | Override cover image for the home page |
| `cover` | Cover folder under `cover/` (e.g. `7x10`); used when resolving the home-page cover |

Cover image resolution order (when `html_cover_image` is not set):

1. `cover/{folder}/3d_front_view.png`
2. `cover/{folder}/cover_front_v2.png`, `cover_front.png`, …
3. Same names under `cover/{folder}/out/`

The active cover folder follows `cover` in config or the print `template` (e.g. `amazon_7x10.tpl` → `7x10`).

## What the HTML site includes

- **Home page** — 3D or flat cover image, book title, chapter count (numbered chapters only), **Start reading**, table of contents
- **Chapter pages** — sticky header (logo, title, purchase link), prev/next chapter navigation, paginated reader for `\newpage` breaks
- **MathJax** — inline and display math from `$…$` / `$$…$$`
- **Cross-references** — `@fig:…`, `@eq:…`, `\eqref{eq:…}`, `Chapter~\ref{chap:…}`, index markers `{.idx}`
- **Semantic blocks** — `>NOTES:`, `>IMPORS:`, `>WARNS:`, `>CENTERS:` / `>CENTERE`, algorithm blocks, fancy dividers, galleries
- **Section sidebar** — foldable in-chapter H2 navigation; collapsed/expanded state persists across chapters (via `localStorage`)
- **Front matter** — preface pagination (cover art, copyright, dedication on its own page, about the author, preface body) without editing source `\newpage` before Dedication (inserted at HTML build time)

## Themes

Built-in themes live in the package under `htmlbook/static/themes/`:

| Theme | Description |
|-------|-------------|
| `default` | Light, indigo accents |
| `dark` | Dark background |
| `minimal` | Reduced chrome |

Select with `--theme` or `html_theme` in config.

## Viewing locally

```bash
bubble-render-html --lang en
xdg-open book_html/index.html    # Linux
open book_html/index.html        # macOS
```

For full pagination and chapter-to-chapter navigation, use a browser with JavaScript enabled. Math rendering requires network access (MathJax CDN) unless you customize the template.

## Differences from PDF

| Feature | PDF | HTML |
|---------|-----|------|
| Engine | Pandoc + LuaLaTeX + Lua filters | Markdown → HTML processor |
| Page size / margins | Template-driven | Responsive CSS |
| Index | LaTeX index generation | Not generated in HTML v1 |
| Cover | PDF cover pages | Home page image only |
| `\newpage` | Print page break | Screen pagination (`page-reader.js`) |

Use PDF for print; use HTML for online reading, review, and companion websites.

## See also

- [Build & convert](commands/build-convert.md) — all build commands
- [Configuration](../configuration.md) — full `peanut.config` reference
- [Multi-language](../multi-language.md) — localized chapter files
- [Covers & templates](../covers-templates.md) — cover folders shared with print builds
