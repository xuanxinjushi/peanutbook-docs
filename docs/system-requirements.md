# System requirements

## Platform

The **`peanutbook` toolchain is supported on Linux only** (Debian/Ubuntu and similar distributions). Examples below use `apt`; adapt package names for your distro.

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

Install TeX on Debian/Ubuntu:

```bash
sudo apt install texlive-full
# or a smaller set: texlive-luatex texlive-xetex texlive-latex-extra
```

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
| **mmdc** or **Node.js** (`npx`) | [Mermaid diagrams](markdown-syntax-extensions.md#mermaid-diagrams) in PDF, EPUB, and HTML |

### Mermaid diagrams (optional)

Mermaid is **optional** — only needed when your book uses ` ```mermaid ` fenced blocks. PDF, EPUB, and HTML all render diagrams to PNG at build time via **mermaid-cli** (`mmdc`).

#### Install Node.js (if you do not have `mmdc`)

Debian/Ubuntu:

```bash
sudo apt install nodejs npm
# Node 18+ recommended; use NodeSource if the distro package is too old:
# https://github.com/nodesource/distributions
node --version
```

#### Option A — global `mmdc` (recommended for frequent builds)

```bash
npm install -g @mermaid-js/mermaid-cli
mmdc --version
which mmdc
```

#### Option B — `npx` (no global install)

If `mmdc` is not on `PATH` but `npx` is available, Peanutbook runs:

```bash
npx -y @mermaid-js/mermaid-cli …
```

The first diagram render may download the CLI package (network required).

#### What Peanutbook needs

| Output | Peanutbook | Mermaid CLI | Pandoc / LaTeX |
|--------|------------|-------------|----------------|
| HTML (`bubble-render-html`) | `pip install peanutbook` | **Yes** (`mmdc` or `npx`) | No |
| PDF / EPUB | `pip install peanutbook` | **Yes** | Yes (PDF); EPUB uses Pandoc only |

Rendered PNGs are cached under `img/.mermaid/` next to each chapter (content-hash filenames). No extra `peanut.config` keys are required.

#### Verify from the source repo

```bash
cd peanutbook
./scripts/test_mermaid_html_fixture.sh    # HTML only — needs mmdc or npx
./scripts/test_mermaid_fixture.sh         # PDF — also needs Pandoc + LaTeX
```

If Mermaid is missing, builds leave the fence as a code block (PDF) or skip the image replacement (HTML logs to stderr).

## EPUB / DOCX

EPUB and DOCX exports use Pandoc. Full-book **EPUB** (`bubble-build --format epub`) runs the same Lua filters as PDF, including Mermaid rendering. Standalone **DOCX** (`bubble-convert file.md --format docx`) does not run the print Lua filter chain. Math and layout may differ from PDF. For Word, optionally provide `reference.docx` in the project root.

## Documentation site

User documentation is published at [peanutbook.readthedocs.io](https://peanutbook.readthedocs.io/). It is built from the public [peanutbook-docs](https://github.com/xuanxinjushi/peanutbook-docs) repository (Markdown + MkDocs config only, no Python source). Install the product via `pip install peanutbook`, not from a public Git clone.
