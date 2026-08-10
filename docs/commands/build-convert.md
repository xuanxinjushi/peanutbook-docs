# Build and convert

## `bubble-convert`

Convert one chapter, all chapters, or an arbitrary Markdown file.

```bash
# Chapter by number
bubble-convert 1
bubble-convert              # all chapters

# Options
bubble-convert 1 --style square --template lulu_7x10
bubble-convert 1 --lang cn
bubble-convert 1 --main-font "EB Garamond" --body-font-pt 11
bubble-convert 1 --optimize-pdf --optimize-pdf-quality ebook

# Non-chapter Markdown
bubble-convert margins/poem.md --format docx
```

### Chapter styles

| `--style` | Description |
|-----------|-------------|
| `circle` | Quarter-circle chapter number |
| `square` | Blue square |
| `none` | Plain chapter opening |

### Output formats

Default is PDF. Alternatives:

```bash
bubble-convert 1 --format epub
bubble-convert 1 --format docx
```

EPUB/DOCX use Pandoc without the full print Lua pipeline — layout may differ from PDF.

### Rendering engine (experimental)

```bash
bubble-convert 1 --engine typst
```

Default is `--engine latex` (the full print pipeline: Lua filters, trim-size template, chapter
headers, watermark/protect, PDF optimization). `--engine typst` is a **fast preview** path:
Pandoc converts the chapter straight to [Typst](https://typst.app/) and `typst compile` produces
the PDF in well under a second, skipping the LaTeX-only machinery entirely. Trade-offs:

- No trim-size template, chapter headers/footers, watermark, or PDF optimization — output uses
  Typst's default page setup, not the book's print layout.
- The print Lua filter chain (note boxes, `@fig:`/`@tbl:`/`@code:` cross-references, equation
  numbering, code line numbers, hbars, …) doesn't run — Pandoc's native Typst writer handles
  headings/code/images/math/tables directly. Note boxes render as plain quoted text;
  `@fig:foo` renders as literal `[fig:foo]` instead of a resolved reference; equation labels
  (`\WFHLABEL:`) are dropped rather than numbered.
- Requires the [`typst`](https://github.com/typst/typst) CLI on `PATH` (not installed by
  `pip install peanutbook`).

Use it to eyeball content/structure while drafting; use the default `--engine latex` for
anything print-bound.

## `bubble-convert-parts`

Build **part divider pages** (Part I, II, …) as standalone PDFs from `partN.md`.

```bash
bubble-convert-parts              # all part*.md
bubble-convert-parts 1            # Part I only
bubble-convert-parts part2
```

Place each `partN.md` in the **first chapter folder** of that part (e.g. `chapter1-topic/part1.md` → `part1.pdf`).

`bubble-build` and `bubble-batch` (PDF only) run this automatically before merging chapters. EPUB/DOCX skips part PDFs.

## `bubble-build`

Assemble the full book from all chapters, preface, appendix, covers, and TOC. PDF builds regenerate part openers via `bubble-convert-parts` before merge.

```bash
bubble-build
bubble-build --style square --max-chapters 21
bubble-build --lang cn --optimize-pdf
bubble-build --cover 7x10-packt
bubble-build --no-cover --style none
bubble-build --format epub
bubble-build --format docx --lang cn    # book_zh.epub
```

### Notable flags

| Flag | Effect |
|------|--------|
| `--no-cover` | Interior-only; output name gets `_interior` suffix |
| `--optimize-pdf` | Shrink PDF (GS for en/sp, qpdf for CJK) |
| `--protect` | Anti-copy rasterization (large files) |
| `--include-appendix` | `true`, `false`, or `auto` |
| `--with-time` | Timestamp in output filename |
| `--engine typst` | Preview mode — see below |

### Typst preview mode (experimental)

```bash
bubble-build --engine typst
```

`bubble-build` normally merges every chapter into one Markdown file and does a single
whole-book Pandoc → LaTeX → compile pass (cover, TOC, trim-size template included).
`--engine typst` does **not** replicate that — there is no merged-book Typst pipeline yet. It
short-circuits to a **per-chapter preview**: the same as running
`bubble-convert <N> --engine typst` for every chapter, producing one `<chapter>.pdf` next to
each chapter's Markdown. No merge, cover, TOC, or template is produced. See
[`bubble-convert` — Rendering engine](#rendering-engine-experimental) for what the Typst path
does and doesn't preserve.

### Output naming

| Locale | Style | Example PDF |
|--------|-------|-------------|
| `en` | square | `book_square.pdf` |
| `cn` | square | `book_zh_square.pdf` |
| `en` | none, no cover | `book_none_interior.pdf` |

## `bubble-merge`

Merge chapter Markdown into review-friendly single files:

```bash
bubble-merge
bubble-merge --en-only
bubble-merge --zh-only
bubble-merge --lang tc
```

Default: auto-detect languages via `locales.langs_for_merge`; warns on partial translations.

## `bubble-proposal`

Single Markdown → proposal PDF (Pandoc + LuaLaTeX/XeLaTeX):

```bash
bubble-proposal querytracker/proposal.md --lang en --style square
bubble-proposal notes/sample.md --lang cn --optimize-pdf
```

YAML front matter (`title`, `author`, `runtitle`, …) enables full U.S. proposal title page layout. Without `title`, output uses compact article style.

## `bubble-paper`

Single Markdown → academic paper PDF (Pandoc + LuaLaTeX):

```bash
bubble-paper --init
bubble-paper paper.md --papersize a4
bubble-paper paper.md --two-column --optimize-pdf
```

YAML front matter: `title`, `author`, `affiliation`, `abstract`, `keywords`, `bibliography` (path to `.bib` for `--citeproc`). Uses `templates/paper_style.tex`.

Sample fixture: `tests/fixtures/sample_paper.md` (author Xuan Xin; math, algorithm, table, citations). Build single- and two-column PDFs plus doc preview PNGs with `./scripts/test_sample_paper.sh`.

## `bubble-monitor`

Watch files and rebuild on save:

```bash
bubble-monitor 1 2 3
bubble-monitor --lang tc 1
```

Requires `watchdog` (installed with bubble).

## `bubble-scaffold`

Interactive project bootstrap:

```bash
bubble-scaffold
bubble-scaffold --chapters 10 --lang both --yes
bubble-scaffold --lang zh --yes
```

Creates chapter stubs, `peanut.config`, and `cover/7x10/` placeholders.

## `bubble-split-pdf`

Split a built PDF into *N* parts (e.g. for platform upload limits):

```bash
bubble-split-pdf book_zh_square.pdf -n 5
bubble-split-pdf --dry-run
```

Requires **qpdf**; page count from `pdfinfo` or PyPDF2.
