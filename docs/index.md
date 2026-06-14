# Peanutbook

**Peanutbook** is a **Markdown-based format for writing books** — a structured syntax and project layout for long-form, print-ready manuscripts (textbooks, technical books, memoirs, and similar works).

It extends ordinary Markdown with chapter conventions, semantic blocks (`>NOTES:` … `>NOTEE`), figures, math, cross-references, multi-language editions, and print metadata. See [What is Peanutbook?](what-is-peanutbook.md) for the full definition.

The **build toolchain** (`pip install bubble-book`) turns Peanutbook source files into PDF, EPUB, and DOCX via Pandoc, LaTeX, and Lua filters.

## Format vs toolchain

| | Peanutbook | `bubble-book` (PyPI) |
|---|------------|----------------------|
| **Role** | Authoring format (`.md` + `peanut.config`) | Build tools (`bubble-build`, …) |
| **You** | Write and organize chapters | Install once, run to export |

```bash
pip install bubble-book
bubble-convert 1
bubble-build --style square
```

## What Peanutbook supports

- Numbered chapters with title pages, preface, and appendix
- Multi-language editions (`chapter1.md`, `chapter1_zh.md`, …)
- Semantic note / important / warning blocks and custom layouts
- Figures, code listings, math, indexes, and cross-references
- Print-on-demand covers and trim sizes (KDP, Lulu, Ingram, …)
- Optional watermarks and PDF protection on output

## Documentation map

| Section | Contents |
|---------|----------|
| [What is Peanutbook?](what-is-peanutbook.md) | Format definition and naming |
| [Installation](installation.md) | Install `bubble-book` |
| [Quick start](quickstart.md) | First build in five minutes |
| [Project layout](project-structure.md) | Peanutbook source tree |
| [Syntax reference](markdown-syntax-extensions.md) | All Peanutbook Markdown extensions |
| [Chapter format](chapter-format.md) | Standard chapter front matter |
| [Configuration](configuration.md) | `peanut.config` keys |
| [Multi-language](multi-language.md) | `--lang`, file suffixes, fonts |
| [Covers & templates](covers-templates.md) | Page sizes, cover folders |
| [Command reference](commands/overview.md) | All `bubble-*` CLI tools |
| [Python API](python-api.md) | `Converter`, `BookBuilder` |
| [System requirements](system-requirements.md) | Pandoc, LaTeX, Ghostscript, qpdf |
| [Watermarks](watermark.md) · [PDF protection](pdf-protection.md) | Post-processing |
| [Cross-references troubleshooting](cross-references-troubleshooting.md) | Fix `??` in PDF |

## Package names (toolchain)

| Context | Name |
|---------|------|
| Format | **Peanutbook** |
| PyPI | `bubble-book` (`pip install bubble-book`) |
| Python import | `bubble` |
| CLI | `bubble-build`, `bubble-convert`, `bubble-batch`, … |

## License

See the main repository license.
