# Multi-language support

Bubble builds the same book in **English**, **Simplified Chinese**, **Traditional Chinese**, **Japanese**, and **Spanish**. Each locale uses a runtime **`--lang` code** paired with a **Markdown file suffix**.

## Locale table

| `--lang` | Markdown suffix | Merged book | PDF example (`--style square`) |
|----------|-----------------|-------------|--------------------------------|
| `en` | (none) `chapterN.md` | `book.md` | `book_square.pdf` |
| `cn` | `_zh` | `book_zh.md` | `book_zh_square.pdf` |
| `tc` | `_tc` | `book_tc.md` | `book_tc_square.pdf` |
| `jp` | `_jp` | `book_jp.md` | `book_jp_square.pdf` |
| `sp` | `_sp` | `book_sp.md` | `book_sp_square.pdf` |

!!! note "Historical naming"
    `cn` is the locale code for **Simplified Chinese**, but source files use the **`_zh` suffix**. `bubble-scaffold --lang zh` creates `*_zh.md` and sets `"lang": "cn"` in `peanut.config`.

## Source layout

Localized Markdown lives **beside** English in the same chapter folders (no separate `locale/` tree):

```
chapter1-vector-space/chapter1.md      # English
chapter1-vector-space/chapter1_zh.md   # cn
chapter1-vector-space/chapter1_tc.md   # tc
chapter1-vector-space/chapter1_jp.md   # jp
chapter1-vector-space/chapter1_sp.md   # sp
```

Shared figures live under `img/` and are reused across languages.

## Commands

```bash
# Full book (default lang from peanut.config)
bubble-build --lang tc
bubble-build --lang jp --style square
bubble-build --lang sp --no-cover --style none

# Single chapter
bubble-convert 3 --lang jp

# Merge for editing
bubble-merge --zh-only
bubble-merge --lang tc
bubble-merge --lang jp

# Watch localized chapters
bubble-monitor --lang tc 1 2 3

# Proposal / sample with CJK
bubble-proposal notes/sample.md --lang jp
```

EPUB/DOCX follow the same stems: `bubble-build --lang tc --format epub` → `book_tc.epub`.

## Typography and PDF optimization

| Locales | LaTeX engine | Fonts | `--optimize-pdf` |
|---------|--------------|-------|------------------|
| `en`, `sp` | LuaLaTeX | Latin (`--main-font` allowed) | Ghostscript `pdfwrite` (`gs` on PATH) |
| `cn`, `tc`, `jp` | XeLaTeX | Noto Serif CJK SC / TC / JP | `qpdf --optimize-images` (preserves CJK bookmarks) |

Install CJK fonts on the build machine (e.g. `fonts-noto-cjk` on Debian/Ubuntu).

## Covers

Optional per-locale cover PDFs in the active cover folder (e.g. `cover/7x10/`):

- `cover_front_zh.pdf` / `cover_back_zh.pdf`
- `_tc`, `_jp`, `_sp` variants

## Editorial helpers (Chinese)

These tools target `*_zh.md` by default:

- `bubble-fix-zh-period`
- `bubble-fix-zh-punct`
- `bubble-fix-zh-quotes`

Extend or duplicate workflows for `_tc.md` / `_jp.md` as needed; Japanese punctuation rules differ from Chinese.

## Locale metadata

Central definitions live in `bubble/locales.py`: `VALID_LANGS`, fonts, UI strings (TOC title, running headers), and output file stems.
