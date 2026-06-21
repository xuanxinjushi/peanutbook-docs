# Project layout

A **Peanutbook** project is a directory of chapter Markdown files, optional localized variants, covers, and `peanut.config`. The build toolchain discovers the **project root** by walking up until it finds chapter folders and/or `peanut.config`.

## Directory tree

```
project_root/
├── peanut.config                 # project overrides (optional)
├── book.md                       # merged English (from bubble-merge)
├── book_zh.md                    # merged cn, etc.
├── chapter1-topic/
│   ├── chapter1.md               # English source
│   ├── chapter1_zh.md            # optional localized chapters
│   ├── chapter1_tc.md
│   ├── chapter1_jp.md
│   ├── chapter1_sp.md
│   └── img/                      # figures; may contain *.py generators
├── chapter2-topic/
│   └── chapter2.md
├── …
├── chapterx/
│   ├── preface.md
│   ├── preface_zh.md
│   ├── chapterx.md               # appendix (English)
│   └── chapterx_zh.md
├── cover/
│   ├── 7x10/                     # default for amazon_7x10 / lulu_7x10
│   │   ├── cover_front.pdf
│   │   ├── cover_front_zh.pdf    # optional per locale
│   │   ├── cover_back.pdf
│   │   ├── cover_front.py        # regenerated before build
│   │   └── cover_back.py
│   ├── 7x10-packt/
│   └── 8.5x11/
├── img/                          # shared images (optional)
├── reference.docx                # optional DOCX style reference
├── epub.css                      # optional EPUB stylesheet override
├── book_html/                    # HTML book site (from bubble-render-html)
└── book_html_zh/                 # localized HTML output
```

## Chapter naming

| Pattern | Meaning |
|---------|---------|
| `chapterN.md` | English chapter *N* |
| `chapterN_zh.md` | Simplified Chinese (`--lang cn`) |
| `chapterN_tc.md` | Traditional Chinese |
| `chapterN_jp.md` | Japanese |
| `chapterN_sp.md` | Spanish |
| `chapterx/chapterx.md` | Appendix (English) |
| `chapterx/preface.md` | Preface |

Chapter folders are typically named `chapter1-something/`, `chapter2-something/`, … Bubble matches by chapter number inside the Markdown filename.

If a localized file is missing for a chapter, the build **falls back** to the English `chapterN.md`.

## Build artifacts

| Command | Typical outputs |
|---------|-----------------|
| `bubble-convert N` | `chapterN…/chapterN.pdf` (or `_zh`, etc.) |
| `bubble-build` | `book_{style}.pdf` or `book_{tag}_{style}.pdf` |
| `bubble-build --no-cover` | `book_{style}_interior.pdf` |
| `bubble-build --format epub` | `book.epub`, `book_zh.epub`, … |
| `bubble-build --format html` | `book_html/`, `book_html_zh/`, … |
| `bubble-render-html` | Same as `--format html` |
| `bubble-batch` | collected copies under `books/` (configurable) |

Temporary files go under `.build/` in the project root during conversion.

## Scaffold a new project

```bash
bubble-scaffold
bubble-scaffold --chapters 10 --lang both --yes
```

Creates chapter stubs, `peanut.config`, and placeholder covers under `cover/7x10/`.
