# Batch release

## `bubble-batch`

Orchestrates a **release build**: full book variants per language, optional per-chapter PDFs, and collection into **`books/`** (override with `--output-dir` or `batch_output_dir` in config).

```bash
bubble-batch
bubble-batch --chapters
bubble-batch --chapters-only
bubble-batch --chapter 1-3
bubble-batch --lang en --cover 7x10 --cover-provider kdp/paperback
bubble-batch --lang en,cn,tc --style none
bubble-batch --lang all --cover 7x10 --cover-provider ingram/hardcover --cover-version v2
bubble-batch --lang all --optimize-pdf
```

Many book repos expose a thin wrapper:

```bash
./run.sh          # exec bubble-batch "$@"
```

## Language selection

| Argument | Behavior |
|----------|----------|
| (none) | Uses `batch_default_langs` from config, or single `lang`, or all scanned langs |
| `--lang en`, `--lang cn`, … | Build only that locale |
| `--lang en,cn,tc` or `--lang en cn tc` | Build multiple locales |
| `--lang all` | Every language with source files |

## Typical outputs per language

Without `--style`, each language gets the release set:

- Full book with cover (style from `batch_cover_style` / peanut.config)
- Interior PDF, **square** (`--no-cover`)
- Interior PDF, **none** (`--no-cover`)

With `--style none` (or `square` / `circle`), only that style is built:

- Full book with cover
- Matching interior (`*_interior.pdf`)

Optional: per-chapter PDFs when `--chapters` is set (also uses `--style` when given).
Use `--chapters-only` to skip full-book builds, and `--chapter SPEC` to select chapters
(`1`, `1-3`, `1,9`).

Files are copied or linked into `books/` (or `batch_output_dir`).

### Cross-chapter references in per-chapter PDFs

By default, each chapter PDF is compiled **standalone** — its own `pandoc` + multi-pass LaTeX
run, isolated from every other chapter. Any `\ref`/`\eqref` pointing at a label defined in a
*different* chapter has no `.aux` entry to resolve against, so it renders as `??`, every time.
This is not a transient "rerun to fix" issue; it's inherent to compiling each chapter in
isolation.

Pass `--chapters-from-book` to avoid it:

```bash
bubble-batch --chapters-only --chapters-from-book
bubble-batch --chapters --chapters-from-book --chapter 1-3
```

This builds one full-book interior PDF (at the chapter style) and slices each chapter's page
range out of it with `qpdf`, instead of recompiling per chapter. Because the source PDF already
went through the full-book multi-pass compile, cross-chapter references resolve correctly.

Page ranges come from the PDF's own bookmarks (one per `\chapter`, written by hyperref), not
from the `.toc` file's page numbers — those record LaTeX's `\thepage` counter, which resets to
Arabic `1` at `\mainmatter` and does **not** match the chapter's actual physical page position
(front matter — cover, copyright, preface, TOC, part dividers — precedes it). Bookmark
destinations give the real physical page regardless of front-matter length. If the build has no
bookmarks (or PyPDF2 isn't installed), `--chapters-from-book` refuses to run rather than slice
from the wrong offset.

Trade-offs vs. the standalone compile:

- Page numbers reflect the book's continuous numbering (not restarted at 1 per chapter).
- `--book-ads` footer text is **not** applied — it's baked into the LaTeX header at compile
  time, and these pages are cut from an already-compiled PDF.
- `--protect` (rasterize) still applies, same as the standalone path.
- Requires `qpdf` on `PATH`.

See [Cross-references troubleshooting](../cross-references-troubleshooting.md) for the full-book
(non-per-chapter) case.

## Cover options

```bash
--cover 7x10
--cover-provider kdp/paperback | ingram/hardcover | lulu/paperback | lulu/hardcover
--cover-version v1 | v2
```

Cover scripts in the active folder run before PDF assembly (see [Covers & templates](../covers-templates.md)).

## Part divider pages

Full-book PDF builds call **`bubble-convert-parts`** before merging chapters. Manual refresh:

```bash
bubble-convert-parts
bubble-convert-parts 1
```

See [Build & convert — `bubble-convert-parts`](build-convert.md#bubble-convert-parts).

## Optimization

PDF optimization follows locale rules (Ghostscript vs qpdf). Controlled by:

- `batch_optimize_pdf` / `batch_optimize_pdf_quality` in `peanut.config`
- CLI: `--optimize-pdf`, `--no-optimize-pdf`, `--optimize-pdf-quality`

## Protected chapter PDFs

Per-chapter builds rasterize PDFs by default. `--no-optimize-pdf` also skips protect
(unless `--protect`); `--no-protect` skips protect only. Ads footer text is independent.

## Config reference

See [Configuration — Batch release keys](../configuration.md#batch-release-keys-bubble-batch).

Per-chapter builds (`--chapters`) use the highest chapter number found under `chapter*/chapter*.md`.
