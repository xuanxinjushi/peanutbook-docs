# Cross-references: `??` in the PDF and wrong label text

## `??` in the PDF (unresolved `\ref`)

LaTeX often exits **non-zero** on the first pass when references are still undefined, while still writing a `.pdf`. If follow-up passes are not run, you keep `Figure ??`, `Chapter ??`, etc.

**Without changing `bubble-build`:** after a build, note the **temp directory** in the log (e.g. `Temp directory: /tmp/ai4math_...`), then run:

```bash
bubble-latex-multi-pass /tmp/ai4math_XXXXX/book_merged.tex
```

Optional flags:

```bash
bubble-latex-multi-pass /path/to/book_merged.tex --engine xelatex --passes 3
```

The script runs `makeindex` when `\printindex` and a `.idx` file exist, then runs the engine several times. The updated `book_merged.pdf` stays in that temp folder; copy it to your project `book.pdf` if needed.

It also writes **`wrong_reference.txt`** in the same directory as the `.tex` file, containing `LaTeX Warning: Reference …`, the “There were undefined references” summary line, and multiply-defined label warnings (override with `--warnings-out /path/to/file.txt`).

## Quick PDF scan (after build)

From the book repo root (needs **poppler-utils** / `pdftotext`):

```bash
bubble-pdfcheck
bubble-pdfcheck book_square.pdf
bubble-pdfcheck --labels-only    # labeleq / WFHLABEL only
```

Reports line numbers for leaked equation labels (`labeleq`, `WFHLABEL`) and unresolved references (`??`) in the extracted PDF text. Exit code 1 when any issue is found.

## Finding broken keys

Search the same directory’s `book_merged.log` for:

- `LaTeX Warning: Reference`
- `There were undefined references`
- `multiply defined`

Those lines name the label keys to fix in chapter Markdown.

## Wrong *human* text next to a reference

That is a **source** issue (typo, renamed label, duplicate `\label` across chapters). Prefer a small static checker over grepping the PDF: collect `\label{…}` / `{#…}` / `@fig:…` definitions vs `\ref{…}` / `@fig:…` uses across `chapter*/chapter*.md`. See `markdown-syntax-extensions.md` for conventions.
