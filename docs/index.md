# Bubble Book

**Bubble** is a Python toolkit for turning Markdown chapters into print-ready books. It wraps Pandoc, LaTeX, and a set of Lua filters and helper scripts into a cohesive build pipeline used by the [Math4AI](https://github.com/juncongmoo/linalg) project and similar multi-chapter book repos.

## What it does

- Convert individual chapters (`chapter1.md`, …) to PDF, EPUB, or DOCX
- Merge all chapters into a full book with automatic table of contents
- Support multiple languages (English, Simplified/Traditional Chinese, Japanese, Spanish)
- Apply chapter decorations (circle, square, or none)
- Attach front/back cover PDFs for print-on-demand (KDP, Lulu, Ingram, …)
- Batch-build release variants (interior + cover, square + none styles)
- Editorial helpers: Chinese punctuation fixes, index terms, watermarks, PDF protection

## Typical workflow

```bash
# 1. Install bubble-book from PyPI
pip install bubble-book

# 2. Scaffold a new book repo (optional)
bubble-scaffold --chapters 10 --lang both

# 3. Edit chapter Markdown, then build one chapter or the full book
bubble-convert 1
bubble-build --style square

# 4. Release batch (optional): all languages × variants → books/
bubble-batch
```

## Documentation map

| Section | Contents |
|---------|----------|
| [Installation](installation.md) | pip, conda, editable install |
| [Quick start](quickstart.md) | First build in five minutes |
| [Project layout](project-structure.md) | Expected folder and file naming |
| [Configuration](configuration.md) | `peanut.config` keys |
| [Multi-language](multi-language.md) | `--lang`, file suffixes, fonts |
| [Covers & templates](covers-templates.md) | Page sizes, cover folders |
| [Command reference](commands/overview.md) | All `bubble-*` CLI tools |
| [Python API](python-api.md) | `Converter`, `BookBuilder` |
| [System requirements](system-requirements.md) | Pandoc, LaTeX, Ghostscript, qpdf |

## Package names

| Context | Name |
|---------|------|
| PyPI (release) | `bubble-book` (`pip install bubble-book`) |
| Import | `bubble` |
| Main CLIs | `bubble-build`, `bubble-convert`, `bubble-batch`, … |

## License

See the main repository license.
