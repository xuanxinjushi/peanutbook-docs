# Project layout

A **Peanutbook** project is a directory of chapter Markdown files, optional localized variants, covers, and `peanut.config`. The build toolchain discovers the **project root** by walking up until it finds chapter folders and/or `peanut.config`.

## Directory tree

```
project_root/
├── peanut.config                 # project overrides (optional)
├── HOW-TO-WRITE.md               # writing guide, conventions, and pre-publication checklist
├── .claude/skills/peanutbook-figures/ # AI agent skills for figures and diagram generation
├── book.md                       # merged English (from bubble-merge)
├── book_zh.md                    # merged cn, etc.
├── chapter1-topic/
│   ├── part1.md                  # optional Part I opener (first chapter of part)
│   ├── part1.pdf                 # from bubble-convert-parts (page 2 = part mindmap if present)
│   ├── chapter1.md               # English source
│   ├── chapter1_zh.md            # optional localized chapters
│   ├── chapter1_tc.md
│   ├── chapter1_jp.md
│   ├── chapter1_sp.md
│   └── img/                      # figures; *.py generators
│       ├── _figstyle.py          # shared styling, fonts, and plot helpers
│       ├── example_figure.py     # runnable example figure (chapter 1)
│       ├── example_figure.png    # rendered figure referenced in chapter1.md
│       ├── part1_mindmap.json    # optional part overview mindmap
│       ├── part1_mindmap.py
│       └── part1_mindmap.png
├── chapter2-topic/
│   ├── chapter2.md
│   └── img/
│       └── _figstyle.py
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
│   │   ├── cover_front_zh.py     # locale-aware wrapper (if lang=zh/both)
│   │   ├── cover_back.py
│   │   └── cover_back_zh.py
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
| `chapter*/partN.md` | Part divider source (e.g. Part I in `chapter1-…/part1.md`) |
| `chapter*/partN.pdf` | Generated part opener (see `bubble-convert-parts`) |

Chapter folders are typically named `chapter1-something/`, `chapter2-something/`, … Bubble matches by chapter number inside the Markdown filename.

If a localized file is missing for a chapter, the build **falls back** to the English `chapterN.md`.

## Build artifacts

| Command | Typical outputs |
|---------|-----------------|
| `bubble-convert N` | `chapterN…/chapterN.pdf` (or `_zh`, etc.) |
| `bubble-convert-parts` | `chapter*/partN.pdf` next to each `partN.md` |
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

Creates:
- Chapter folder stubs (`chapter1-topic/`, …) with starter markdown.
- Chapter 1 working demo figure (`img/example_figure.py` and pre-rendered `example_figure.png`).
- Per-chapter `img/_figstyle.py` with shared layout styling and LaTeX fonts.
- Project-level `HOW-TO-WRITE.md` containing authoring guidelines and pre-publication checks.
- Agent skill under `.claude/skills/peanutbook-figures/` for automated diagram generation.
- Placeholder cover scripts under `cover/7x10/` (including `cover_front_zh.py` / `cover_back_zh.py` for Chinese/bilingual projects).
- Starter `peanut.config`.

