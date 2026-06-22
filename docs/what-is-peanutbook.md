# What is Peanutbook?

**Peanutbook** is a **book-writing format** built on Markdown. It is not a generic Markdown dialect for web pages or notes — it is a structured way to author **long-form, print-ready books** (technical manuals, textbooks, memoirs, and similar projects).

Peanutbook extends CommonMark-style Markdown with conventions and markers for:

- **Book structure** — numbered chapters, preface, appendix, multi-language editions
- **Chapter front matter** — title, subtitle, epigraph, code summary (see [Chapter format](chapter-format.md))
- **Semantic blocks** — NOTE, IMPORTANT, WARNING, centered dedication pages, and more (see [Syntax reference](markdown-syntax-extensions.md))
- **Figures, code, math, cross-references, and indexes** — labels and filters tuned for PDF, not HTML
- **Conditional includes** — audience-specific fragments via `peanut.config`
- **Print metadata** — covers, trim sizes, running headers, TOC strings per locale

Authors write **Peanutbook source** as plain `.md` files in a standard project layout ([Project layout](project-structure.md)).

## Peanutbook vs the build toolchain

| Name | What it is |
|------|------------|
| **Peanutbook** | The **format** — Markdown files, syntax markers, folder layout, `peanut.config` |
| **`bubble-book`** (PyPI) | The **toolchain** — `bubble-build`, `bubble-convert`, `bubble-render-html`, Lua filters, LaTeX templates, HTML renderer |

You do not “run Peanutbook” as a program. You **write** Peanutbook and **build** it with the toolchain:

```bash
pip install bubble-book
bubble-convert 1          # one chapter → PDF
bubble-build --style square   # full book → PDF
bubble-render-html            # full book → HTML site
bubble-bizplan bizplan.md     # AI4Biz business plan → PDF
```

The Python package import name remains `bubble` for historical reasons; the public name for the format is **Peanutbook**.

## Why a dedicated format?

Generic Markdown tools assume one document or a simple website. Books need:

- Consistent chapter openings and page breaks
- Stable cross-chapter figure and equation numbering
- Index generation and multi-pass LaTeX
- Parallel language editions (`chapter1.md`, `chapter1_zh.md`, …)
- Print-on-demand cover and interior variants

Peanutbook encodes these requirements in **source conventions** so the same files can produce PDF, EPUB, and DOCX through one pipeline.

## Where to start

1. [Quick start](quickstart.md) — install and first build  
2. [Chapter format](chapter-format.md) — required chapter header structure  
3. [Syntax reference](markdown-syntax-extensions.md) — all Peanutbook markers and extensions  
4. [Configuration](configuration.md) — `peanut.config` for your project  

Documentation: [peanutbook.readthedocs.io](https://peanutbook.readthedocs.io/)
