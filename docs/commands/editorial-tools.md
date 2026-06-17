# Editorial tools

Helper commands for manuscript cleanup, indexing, and PDF post-processing. Most operate on `chapter*/*.md` under the project root.

## Chinese text normalization

Target **Simplified Chinese** sources (`*_zh.md`):

```bash
bubble-fix-zh-period
bubble-fix-zh-punct
bubble-fix-zh-quotes
```

Run from the book repo root. Review diffs before committing — these are batch text transforms.

## Markdown style checks

```bash
# Whole-line *single-star* emphasis → _underscore_ (excludes chapter title line 3)
bubble-single-star
bubble-single-star --include-merged
bubble-single-star --write

# Headings that should not be bold
bubble-bold-headings

# Colon-separated list consistency
bubble-check

# Built PDF: leaked equation labels and unresolved cross-references
bubble-pdfcheck
bubble-pdfcheck book_square.pdf
bubble-pdfcheck --labels-only
```

## Index and structure

```bash
bubble-index                    # add index terms to Markdown
bubble-extract-chapter-title    # extract title quote from chapter front matter
bubble-count-chars              # character counts
```

## Code and math blocks

```bash
bubble-add-code-annotations
bubble-process-code-annotations
bubble-process-code-explain
bubble-add-math-summaries
```

These prepare or post-process Pandoc/Lua filter markers used during PDF build.

## Includes and preprocessing

```bash
bubble-process-includes         # expand {% include %} directives
```

Run automatically during `bubble-convert` / `bubble-build`, but can be invoked standalone for debugging.

## Images and tables

```bash
bubble-image                    # image cleanup
bubble-set-image-dpi            # DPI metadata
bubble-convert-svg-text         # SVG foreignObject → text for LaTeX
bubble-fix-table-width          # wide table fixes
```

## PDF post-processing

```bash
bubble-add-watermark INPUT.pdf --text "DRAFT"
bubble-protect-pdf book.pdf     # anti-OCR rasterization (--protect-dpi)
bubble-reorder-cover-preface    # cover/preface page order
bubble-split-pdf book.pdf -n 5  # split for upload
bubble-docx-footer              # Word header/footer patches
```

## Cover generation

```bash
bubble-gen-cover-bg             # matplotlib cover background
bubble-gen-latex-header         # debug LaTeX header generation
bubble-gen-toc                    # standalone TOC generation
```

`bubble-gen-cover-bg` requires **matplotlib** and **numpy**.

## LaTeX debugging

```bash
bubble-latex-multi-pass         # multi-pass LaTeX with index
```

Useful when isolating LaTeX failures outside the full build orchestrator.
