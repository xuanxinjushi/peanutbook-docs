# Academic papers

Peanutbook includes a workflow for **research and academic papers**: one Markdown file → PDF with article layout, title block, abstract, keywords, and optional bibliography.

This path uses the **`bubble-paper`** command. It does not use chapter folders, `peanut.config`, or book print templates.

## Quick start

```bash
bubble-paper --init              # scaffold paper.md in cwd
# edit paper.md (YAML front matter + sections)
bubble-paper paper.md              # build PDF next to the .md file
```

Alternative scaffold:

```bash
bubble-scaffold --paper
```

## Command reference

| Flag | Effect |
|------|--------|
| `markdown` | Input `.md` path (required unless `--init`) |
| `-o`, `--output` | Output PDF path (default: same basename as input) |
| `--init` | Write bundled `paper.md` template to cwd |
| `--lang` | Document language (`en`, `cn`, `tc`, `jp`, `sp`) — CJK uses LuaLaTeX + `luatexja` |
| `--papersize` | `a4` (default) or `letter` |
| `--two-column` | Two-column article layout |
| `--template` | Optional custom Pandoc LaTeX template |
| `--optimize-pdf` | Shrink PDF with Ghostscript (or qpdf for CJK) when output is large enough |
| `--optimize-pdf-quality` | `screen`, `ebook`, `printer`, `prepress` (English Ghostscript only) |
| `--style` | Ignored (accepted for script compatibility with `bubble-build`) |

Examples:

```bash
bubble-paper paper.md --papersize a4
bubble-paper paper.md --two-column --optimize-pdf
bubble-paper paper.md --lang cn
```

## YAML front matter

Optional YAML at the top of the Markdown drives the title page and metadata:

```yaml
---
title: "Paper Title"
author: "Author Name"
affiliation: "Department, University"
date: "\\today"
abstract: |
  Summarize the problem, approach, and main results.
keywords: "machine learning, NLP, evaluation"
bibliography: references.bib
---
```

| Key | Purpose |
|-----|---------|
| `title` | Paper title (centered on title block) |
| `author` | Author name(s) |
| `affiliation` | Institution or department (shown under author) |
| `date` | Publication date (LaTeX `\\today` or a fixed string) |
| `abstract` | Abstract paragraph (rendered in an **Abstract** block) |
| `keywords` | Keyword line printed after the abstract |
| `bibliography` | Path to a `.bib` file (enables Pandoc `--citeproc`) |

For two-column layout you can also set `layout: two-column` in YAML instead of `--two-column`.

## Suggested structure

The bundled template includes typical sections:

1. **Introduction**
2. **Related Work**
3. **Method**
4. **Experiments**
5. **Conclusion**
6. **Acknowledgments** (optional subsection)
7. **References** (filled when `bibliography` is set)

Sections are numbered automatically (`--number-sections`). Use standard Peanutbook Markdown for figures, math, tables, and code blocks — see [Syntax reference](markdown-syntax-extensions.md).

## Bibliography

When `bibliography: references.bib` is set and the file exists next to the Markdown (or at the given path), `bubble-paper` runs Pandoc with `--citeproc`. Add citation keys in the body:

```markdown
Prior work [@smith2020] showed ...
```

## PDF styling

`bubble-paper` includes `templates/paper_style.tex` via Pandoc `-H`:

- Serif body (TeX Gyre Termes or Latin Modern Roman)
- Blue title and section headings
- Abstract block with **Keywords** line when `keywords` is set
- 11pt article, **1-inch** margins single-column / **0.75-inch** margins two-column (default **A4**)

For book proposals, use [`bubble-proposal`](commands/build-convert.md#bubble-proposal) instead. For business plans, see **[Business plans](bizplan.md)**.

## Python API

```python
from pathlib import Path
from bubble.paper import build_paper_pdf

build_paper_pdf(
    Path("paper.md"),
    Path("paper.pdf"),
    lang="en",
    papersize="a4",
    two_column=False,
    optimize_pdf=False,
)
```

`build_paper_pdf` returns `0` on success, non-zero on failure. CLI equivalent: `bubble-paper`.

## Layout previews

The sample fixture is built in **single-column** (default) and **two-column** (`--two-column`) layouts. Regenerate previews with `./scripts/test_sample_paper.sh` in the peanutbook repository.

### Single column

![Single-column academic paper preview — title block, abstract, math, algorithm, and references](img/paper-preview-single.png)

### Two column

![Two-column academic paper preview — same content in twocolumn article layout](img/paper-preview-twocol.png)

## Sample fixture

A minimal end-to-end example lives in the **peanutbook** source repository:

| File | Purpose |
|------|---------|
| `tests/fixtures/sample_paper.md` | Sample paper by **Xuan Xin** with abstract, display math, algorithm block, code, table, and citations |
| `tests/fixtures/sample_paper.bib` | BibTeX references for `--citeproc` |
| `scripts/test_sample_paper.sh` | Builds single- and two-column PDFs plus preview PNGs |

```bash
./scripts/test_sample_paper.sh
```

Outputs:

| Artifact | Description |
|----------|-------------|
| `tests/output/sample_paper.pdf` | Single-column preview |
| `tests/output/sample_paper_twocol.pdf` | Two-column preview |
| `docs/img/paper-preview-single.png` | Documentation screenshot (single column) |
| `docs/img/paper-preview-twocol.png` | Documentation screenshot (two column) |

### Algorithms and math

The sample paper includes display equations (attention, multi-head, layer norm) and a fenced algorithm block:

````markdown
```{.algorithm caption="Scaled Dot-Product Attention" label="alg:attention"}
\Require Matrices $Q, K, V$ with compatible inner dimension $d_k$
\Ensure Attention output $A$
\State $S \gets Q K^\top / \sqrt{d_k}$
...
```
````

`bubble-paper` applies `scripts/algorithm_blocks.lua` automatically. Cross-references use raw LaTeX, e.g. `Algorithm~\ref{alg:attention}`.

Two-column builds also enable `scripts/paper_floating_tables.lua` so tables use floating `table` environments instead of `longtable` (which fails in `twocolumn` mode).

### Code line numbers

`bubble-paper` enables **left-aligned line numbers** on fenced code blocks by default (listings `numbers=left`). Disable for a single block with a `#NOLINENUM` marker at the top of the block (same as books). Re-enable an individual block with `#LINENUM` when line numbers are off.

## See also

- [Build & convert — `bubble-paper`](commands/build-convert.md#bubble-paper) — short CLI summary
- [Command reference overview](commands/overview.md)
- [System requirements](system-requirements.md) — Pandoc, LuaLaTeX
