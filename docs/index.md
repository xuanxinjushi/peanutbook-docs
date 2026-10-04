# Peanutbook

**Peanutbook** is a **Markdown-based format for writing books, papers, business plans, and static websites** — a structured syntax and project layout for long-form, print-ready documents (textbooks, technical books, memoirs, research papers, business plans, and similar works).

![Peanut the dog and Bubble the rabbit](peanut_bubble.jpg)

It extends ordinary Markdown with chapter conventions, semantic blocks (`>NOTES:` … `>NOTEE`), figures, math, cross-references, multi-language editions, and print metadata. See [What is Peanutbook?](what-is-peanutbook.md) for the full definition.

The **build toolchain** (`pip install peanutbook`) turns Peanutbook source files into PDF, EPUB, DOCX, and **static HTML book sites** via Pandoc, LaTeX, Lua filters (including [Mermaid diagram rendering](markdown-syntax-extensions.md#mermaid-diagrams)), and the built-in HTML renderer.

Peanutbook uses bubble-build.

## Format vs toolchain

| | Peanutbook | `peanutbook` (PyPI) |
|---|------------|----------------------|
| **Role** | Authoring format (`.md` + `peanut.config`) | Build tools (`bubble-build`, …) |
| **You** | Write and organize chapters | Install once, run to export |

```bash
pip install peanutbook
bubble-convert 1
bubble-build --style square
```

## What Peanutbook supports

- Numbered chapters with title pages, preface, and appendix
- Multi-language editions (`chapter1.md`, `chapter1_zh.md`, …)
- Semantic note / important / warning blocks and custom layouts
- Figures, code listings, math, indexes, and cross-references
- Print-on-demand covers and trim sizes (KDP, Lulu, Ingram, …)
- Static HTML book sites (`book_html/`) for online reading
- Business plans (`bubble-bizplan`, `peanut-biz.config`) — see [Business plans](bizplan.md)
- Academic papers (`bubble-paper`) — see [Academic papers](paper.md) (single- and two-column PDF previews)
- Optional watermarks and PDF protection on output

## Documentation map

| Section | Contents |
|---------|----------|
| [What is Peanutbook?](what-is-peanutbook.md) | Format definition and naming |
| [Installation](installation.md) | Install `peanutbook` |
| [Quick start](quickstart.md) | First build in five minutes |
| [Project layout](project-structure.md) | Peanutbook source tree |
| [Syntax reference](markdown-syntax-extensions.md) | All Peanutbook Markdown extensions |
| [Chapter format](chapter-format.md) | Standard chapter front matter |
| [Configuration](configuration.md) | `peanut.config` keys |
| [Theme](theme.md) | Colors, chapter opener, quote style (no LaTeX) |
| [Multi-language](multi-language.md) | `--lang`, file suffixes, fonts |
| [Covers & templates](covers-templates.md) | Page sizes, cover folders |
| [Bookshelf covers & multi-language](shelf-covers.md) | Cover discovery, resolution order, and multi-edition cards |
| [Cover fonts](fonts.md) | Cover font choices, system-font limits, and expansion plan |
| [Font selector implementation plan](fonts-plan.md) | Dynamic system-font discovery and fallback implementation |
| [Business plans](bizplan.md) | Business-plan workflow (`bubble-bizplan`, `peanut-biz.config`) |
| [Academic papers (bubble-paper)](paper.md) | Research-paper workflow, layout previews |
| [HTML generation](html-generation.md) | Static book site (`bubble-render-html`) |
| [VS Code extension](vscode-extension.md) | In-editor PDF preview with rebuild-on-save |
| [Book workspace (Online Writer)](online-book-folder-design.md) | In-browser workspace: multi-tab editor, tree context menu, layout toggles, Live preview |
| [Command reference](commands/overview.md) | All `bubble-*` CLI tools |
| [Python API](python-api.md) | `Converter`, `BookBuilder` |
| [System requirements](system-requirements.md) | Pandoc, LaTeX, Ghostscript, qpdf |
| [Watermarks](watermark.md) · [PDF protection](pdf-protection.md) | Post-processing |
| [Cross-references troubleshooting](cross-references-troubleshooting.md) | Fix `??` in PDF |

## Internal / ops notes (not published)

Private, not mirrored to `peanutbook-docs` -- deployment/runbook notes for
this repo's own companion apps, not the Peanutbook format/toolchain itself.

| Section | Contents |
|---------|----------|
| Launching a new book's website (`docs/new-book-website.md`) | `web/booksite` deployment runbook -- Docker (recommended) and non-Docker paths, `/admin/` setup, gotchas hit building it |

## Package names (toolchain)

| Context | Name |
|---------|------|
| Format | **Peanutbook** |
| PyPI | `peanutbook` (`pip install peanutbook`) |
| Python import | `bubble` |
| CLI | `bubble-build`, `bubble-convert`, `bubble-convert-parts`, `bubble-render-html`, `bubble-batch`, … |

## License

This project is licensed under the Apache License, Version 2.0.

## Contact

Xuan Xin — xuanxinjushi [at] gmail [dot] com
