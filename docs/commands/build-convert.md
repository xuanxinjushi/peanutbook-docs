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

## `bubble-build`

Assemble the full book from all chapters, preface, appendix, covers, and TOC.

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

## `bubble-bizplan`

Single Markdown → AI4Biz Business Plan PDF (Pandoc + LuaLaTeX):

```bash
bubble-bizplan                 # Defaults to compiling local bizplan.md if no input is specified
bubble-bizplan bizplan.md --cover-name tech-white
bubble-bizplan bizplan.md --strict
bubble-bizplan bizplan.md --check-only
```

Validates required narrative structure, enforces double-spacing, 12pt Times font, and 1-inch margins. Scaffolds a business plan template via `--init`:

```bash
bubble-bizplan --init bizplan.md
```

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
bubble-scaffold --bizplan
```

Creates chapter stubs, `peanut.config`, and `cover/7x10/` placeholders. If `--bizplan` is specified, scaffolds a business plan template (`bizplan.md`) instead.

## `bubble-split-pdf`

Split a built PDF into *N* parts (e.g. for platform upload limits):

```bash
bubble-split-pdf book_zh_square.pdf -n 5
bubble-split-pdf --dry-run
```

Requires **qpdf**; page count from `pdfinfo` or PyPDF2.
