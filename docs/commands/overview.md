# Command overview

After `pip install -e .` (or `pip install bubble-book`), every tool is available as a **`bubble-*` console script**. Run any command with `--help` where supported.

## Primary workflows

| Command | Module | Purpose |
|---------|--------|---------|
| `bubble-build` | `build_book.py` | Merge chapters → full book PDF/EPUB/DOCX |
| `bubble-convert` | `convert.py` | Single chapter (or all) → PDF/EPUB/DOCX |
| `bubble-batch` | `batch_build.py` | Multi-lang release orchestration → `books/` |
| `bubble-merge` | `merge_books.py` | Concatenate chapters → `book.md`, `book_zh.md`, … |
| `bubble-scaffold` | `scaffold.py` | Create new bubble-compatible repo |
| `bubble-monitor` | `monitor.py` | Watch Markdown and auto-rebuild |
| `bubble-proposal` | `proposal.py` | One-off proposal / query letter PDF |

## Build pipeline helpers

| Command | Purpose |
|---------|---------|
| `bubble-gen-latex-header` | Generate LaTeX preamble from template + config |
| `bubble-gen-toc` | Table of contents generation |
| `bubble-latex-multi-pass` | Multi-pass LaTeX (index, references) |
| `bubble-process-includes` | Expand `{% include %}` in Markdown |
| `bubble-reorder-cover-preface` | Reorder cover/preface pages in PDF |
| `bubble-split-pdf` | Split large PDF for upload (needs qpdf) |
| `bubble-protect-pdf` | Copy/print protection (rasterizes pages) |
| `bubble-add-watermark` | Text or image watermark |

## Editorial & quality

| Command | Purpose |
|---------|---------|
| `bubble-fix-zh-period` | Chinese period normalization (`*_zh.md`) |
| `bubble-fix-zh-punct` | Chinese punctuation |
| `bubble-fix-zh-quotes` | Curly quotes → Chinese quotes |
| `bubble-single-star` | Find/fix whole-line `*emphasis*` (→ `_underscore_`) |
| `bubble-bold-headings` | Check headings for spurious bold |
| `bubble-check` | Colon-list consistency check |
| `bubble-count-chars` | Character counts per chapter |
| `bubble-index` | Add index terms |
| `bubble-extract-chapter-title` | Extract chapter title quote |

## Code & math in Markdown

| Command | Purpose |
|---------|---------|
| `bubble-add-code-annotations` | Code block annotations |
| `bubble-process-code-annotations` | Process annotation markers |
| `bubble-process-code-explain` | Code explanation blocks |
| `bubble-add-math-summaries` | Math summary boxes |

## Figures & covers

| Command | Purpose |
|---------|---------|
| `bubble-image` | Clean/normalize images |
| `bubble-set-image-dpi` | Set image DPI metadata |
| `bubble-convert-svg-text` | SVG foreignObject → text |
| `bubble-fix-table-width` | Table width fixes |
| `bubble-gen-cover-bg` | Generate cover background (matplotlib) |

## Export extras

| Command | Purpose |
|---------|---------|
| `bubble-docx-footer` | Patch Word header/footer |

## Running scripts directly

Each `bubble-*` command maps to `bubble/scripts/<name>.py` or a top-level module. Equivalent:

```bash
python -m bubble.build_book --help
python3 shared/bubble/scripts/count_chars.py
```

## See also

- [Build & convert](build-convert.md)
- [Batch release](batch-release.md)
- [Editorial tools](editorial-tools.md)
