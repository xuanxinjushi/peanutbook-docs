# Quick start

This guide assumes you have a **Peanutbook** project (Markdown chapters + `peanut.config`), or you ran `bubble-scaffold` to create one. See [Project layout](project-structure.md).

## 1. Configure the project

Create or edit `peanut.config` in the book repo root:

```json
{
  "lang": "en",
  "chapter_style": "circle",
  "template": "amazon_7x10.tpl",
  "book_title": "Your Book Title"
}
```

## 2. Build one chapter

From the book repo root:

```bash
bubble-convert 1
```

Output PDF appears next to the chapter (e.g. `chapter1-vector-space/chapter1.pdf`).

Options:

```bash
bubble-convert 1 --style square --template lulu_7x10
bubble-convert 3 --lang cn
bubble-convert margins/poem.md --format docx
```

## 3. Build the full book

```bash
bubble-build
```

Produces `book_circle.pdf` (or `book_square.pdf` / `book_none.pdf` depending on `--style`).

Common flags:

```bash
bubble-build --style square
bubble-build --max-chapters 21
bubble-build --no-cover --style none          # KDP interior-only
bubble-build --lang cn --optimize-pdf
bubble-build --format epub                    # book.epub
```

## 4. Merge chapters for editing

`bubble-merge` concatenates chapter Markdown into a single file for review:

```bash
bubble-merge              # all detected languages
bubble-merge --en-only
bubble-merge --zh-only    # book_zh.md (Simplified Chinese)
```

## 5. Batch release build

For publishing multiple language/style variants into `books/`:

```bash
bubble-batch
bubble-batch --chapters
bubble-batch all --cover 7x10 --cover-provider kdp/paperback
```

Many projects wrap this as `./run.sh` → `bubble-batch "$@"`.

## 6. Watch mode (development)

Auto-rebuild when Markdown changes:

```bash
bubble-monitor 1 2 3
bubble-monitor --lang cn 1
```

## Next steps

- [Multi-language](multi-language.md) — `_zh`, `_tc`, `_jp`, `_sp` files
- [Covers & templates](covers-templates.md) — `--cover`, trim sizes
- [Command reference](commands/overview.md) — full CLI list
