# Batch release

## `bubble-batch`

Orchestrates a **release build**: full book variants per language (cover + square interior + none interior), optional per-chapter PDFs, and collection into **`books/`** (override with `--output-dir` or `batch_output_dir` in config).

```bash
bubble-batch
bubble-batch --chapters
bubble-batch --chapters-only
bubble-batch --chapters-only --chapter 1
bubble-batch --chapter 1-3
bubble-batch --chapter 1,9
bubble-batch en --cover 7x10 --cover-provider kdp/paperback
bubble-batch en,cn,tc --style square --chapter-opener-size 2
bubble-batch all --cover 7x10 --cover-provider ingram/hardcover --cover-version v2
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
| `en`, `cn`, … | Build only that locale |
| `en cn tc` or `en,cn,tc` | Build multiple locales (space- or comma-separated) |
| `all` | Every language with source files |

## Typical outputs per language

For each selected language, batch generally produces:

- Full book with cover (`square` style by default for cover build)
- Interior PDF (`square` + `none` styles, often with `--no-cover`)
- Optional: per-chapter PDFs when `--chapters` is set
- Chapters only (no full book): `--chapters-only`, optionally filtered with `--chapter SPEC`
  - `--chapter 1` → chapter 1
  - `--chapter 1-3` → chapters 1, 2, 3
  - `--chapter 1,9` → chapters 1 and 9
  - `--chapter` alone (without `--chapters`) also skips the full book

Files are copied or linked into `books/` (or `batch_output_dir`).

## Cover options

```bash
--cover 7x10
--cover-provider kdp/paperback | ingram/hardcover | lulu/paperback | lulu/hardcover
--cover-version v1 | v2
```

Cover scripts in the active folder run before PDF assembly (see [Covers & templates](../covers-templates.md)).

## Part divider pages

Full-book PDF builds (`bubble-batch` without `--format` override) call **`bubble-convert-parts`** before merging chapters, so `partN.pdf` stays in sync with `partN.md`. To refresh part pages without a full book build:

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

When building per-chapter PDFs, pages are rasterized (anti-copy/OCR) **by default**.
`--no-optimize-pdf` also skips that protect/rasterize step (keeps the vector LaTeX PDF),
unless you pass `--protect`. Use `--no-protect` to skip protect while still allowing
`--optimize-pdf`. Ads footer text (`--book-ads` / `batch_book_ads`) is independent of protect.

## Config reference

See [Configuration — Batch release keys](../configuration.md#batch-release-keys-bubble-batch).

Per-chapter builds (`--chapters` / `--chapters-only`) use the highest chapter number found under `chapter*/chapter*.md`, unless `--chapter SPEC` selects a subset.
