# System requirements

## Python

- **Python 3.9+** (3.12 recommended)
- Package dependency: `watchdog` (file monitor); release wheels also use `pyzipper`

## Required for PDF builds

| Tool | Purpose |
|------|---------|
| [Pandoc](https://pandoc.org/) | Markdown → LaTeX / EPUB / DOCX |
| **LuaLaTeX** | English and Spanish PDF |
| **XeLaTeX** | Chinese, Traditional Chinese, Japanese PDF |
| **makeindex** | Keyword index (`bubble-index`) |

Install a full TeX distribution:

- Debian/Ubuntu: `texlive-full` or minimal `texlive-luatex`, `texlive-xetex`, `texlive-latex-extra`
- macOS: MacTeX

## Fonts

| Locale | Font |
|--------|------|
| `en`, `sp` | Any OpenType font via `--main-font` / `main_font` in config |
| `cn` | Noto Serif CJK **SC** |
| `tc` | Noto Serif CJK **TC** |
| `jp` | Noto Serif CJK **JP** |

Debian/Ubuntu: `fonts-noto-cjk`

## Optional tools

| Tool | Used by |
|------|---------|
| **Ghostscript** (`gs`) | `--optimize-pdf` for English/Spanish |
| **qpdf** | `--optimize-pdf` for CJK; `bubble-split-pdf` |
| **PyPDF2** or **pdfinfo** (poppler) | Page count for split PDF |
| **pdftotext** (poppler-utils) | `bubble-pdfcheck` — scan built PDFs for `??` and leaked labels |
| **matplotlib**, **numpy** | `bubble-gen-cover-bg` |
| Conda env named in config | Running figure scripts in `chapter*/img/` |

## EPUB / DOCX

EPUB and DOCX exports use Pandoc only (no print Lua filter chain). Math and layout may differ from PDF. For Word, optionally provide `reference.docx` in the project root.

## Documentation site

User documentation is published at [peanutbook.readthedocs.io](https://peanutbook.readthedocs.io/). It is built from the public [peanutbook-docs](https://github.com/xuanxinjushi/peanutbook-docs) repository (Markdown + MkDocs config only, no Python source). Install the product via `pip install peanutbook`, not from a public Git clone.
