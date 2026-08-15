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

## Internationalization & Cross-References (`i18n.json`)

Peanutbook uses a JSON-driven internationalization system for cross-references (`@fig:...`, `@tbl:...`, `@chap:...`), chapter number formatting, and EPUB file chunk naming.

### Global & Project-Local Overrides

1. **System Defaults**: Located in `scripts/i18n.json`.
2. **Author Project Overrides**: Place an `i18n.json` or `peanut.i18n.json` file in your book project root directory. Local entries automatically merge with and override system defaults.

### Example `i18n.json`

```json
{
  "frontmatter_categories": {
    "copyright": ["copyright", "credits", "版权", "版權", "致谢"],
    "preface": ["preface", "前言", "自序"],
    "foreword": ["foreword", "序言", "序", "推荐序"],
    "appendix": ["appendix", "附录", "附錄"],
    "about": ["about author", "关于作者", "關於作者"]
  },
  "languages": {
    "zh-hans": {
      "prefix_names": {
        "fig": "图",
        "tbl": "表",
        "code": "代码",
        "sec": "节",
        "chap": "第"
      },
      "chap_num_format": "第 {num} 章",
      "chapter_patterns": [
        "^[Cc]hapter%s+(%d+)",
        "^第%s*([%d一二三四五六七八九十]+)%s*章"
      ],
      "prefix_words": {
        "fig": ["如图", "见图", "图"]
      },
      "chapter_words": ["chapter", "第", "章", "参见第"]
    }
  }
}
```

### EPUB 1-to-1 Chapter File Naming

When building EPUB (`bubble-build --format epub`), Peanutbook uses `i18n.json` to assign clean, 1-to-1 filenames:

- **Frontmatter / Backmatter**: `cover.xhtml`, `copyright.xhtml`, `preface.xhtml`, `foreword.xhtml`, `appendix.xhtml`, `about.xhtml`
- **Formal Chapters**: `ch001.xhtml` for Chapter 1, `ch002.xhtml` for Chapter 2, ..., `ch019.xhtml` for Chapter 19!

## Locale metadata

Central definitions live in `bubble/locales.py`: `VALID_LANGS`, fonts, UI strings (TOC title, running headers), and output file stems.

