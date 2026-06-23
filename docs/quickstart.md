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
bubble-convert 1 --chapter-opener-size 5
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
bubble-build --chapter-opener-size 5
bubble-build --max-chapters 21
bubble-build --no-cover --style none          # KDP interior-only
bubble-build --lang cn --optimize-pdf
bubble-build --format epub                    # book.epub
bubble-build --format html                    # book_html/
```

## 4. HTML book site (optional)

For an online-readable edition alongside print:

```bash
bubble-render-html
# or
bubble-build --format html
```

See [HTML generation](html-generation.md) for `peanut.config` keys (`html_site_logo`, `html_purchase_url`, themes, etc.).

## 5. Merge chapters for editing

`bubble-merge` concatenates chapter Markdown into a single file for review:

```bash
bubble-merge              # all detected languages
bubble-merge --en-only
bubble-merge --zh-only    # book_zh.md (Simplified Chinese)
```

## 6. Batch release build

For publishing multiple language/style variants into `books/`:

```bash
bubble-batch
bubble-batch --chapters
bubble-batch all --cover 7x10 --cover-provider kdp/paperback
```

Many projects wrap this as `./run.sh` → `bubble-batch "$@"`.

## 7. Watch mode (development)

Auto-rebuild when Markdown changes:

```bash
bubble-monitor 1 2 3
bubble-monitor --lang cn 1
```

## 8. Business plan (optional)

For a single-file business plan (not a multi-chapter book):

```bash
bubble-bizplan --init bizplan.md
bubble-bizplan bizplan.md --cover-name tech-white
```

See **[Business plans](bizplan.md)** for required sections, `peanut-biz.config`, and cover styles.

## Next steps

- [Business plans](bizplan.md) — `bubble-bizplan`
- [Multi-language](multi-language.md) — `_zh`, `_tc`, `_jp`, `_sp` files
- [Covers & templates](covers-templates.md) — `--cover`, trim sizes
- [HTML generation](html-generation.md) — static book site
- [Command reference](commands/overview.md) — full CLI list
