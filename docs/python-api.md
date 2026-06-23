# Python API

Bubble exposes two main orchestrators for programmatic use. Install the package first (`pip install peanutbook`).

## Convert a chapter — `Converter`

```python
from pathlib import Path
from bubble.convert import Converter, ChapterStyle, BuildMode

converter = Converter(
    project_root=Path.cwd(),
    chapter_style=ChapterStyle.CIRCLE,
    mode=BuildMode.DEV,
    # chapter_opener_size_cm=5.0,
    # main_font="EB Garamond",
    # body_font_pt="11",
)

# Single chapter by number
converter.convert("1")

# All chapters
converter.convert()
```

### Enums

| Class | Values |
|-------|--------|
| `ChapterStyle` | `CIRCLE`, `SQUARE`, `NONE` |
| `BuildMode` | `DEV` (lenient), `CI` (strict) |

CLI equivalent: `bubble-convert`.

## Build a full book — `BookBuilder`

```python
from pathlib import Path
from bubble.build_book import BookBuilder, ChapterStyle

builder = BookBuilder(
    project_root=Path.cwd(),
    chapter_style=ChapterStyle.CIRCLE,
    max_chapters=21,
    # chapter_opener_size_cm=5.0,
    # output_format="epub",  # or "docx"; default "pdf"
)

builder.build()
```

CLI equivalent: `bubble-build`.

## Business plans — `build_bizplan_pdf`

```python
from pathlib import Path
from bubble.bizplan import build_bizplan_pdf, validate_markdown_sections, load_peanut_biz_config

missing = validate_markdown_sections(Path("bizplan.md"))
cfg = load_peanut_biz_config(Path.cwd())

build_bizplan_pdf(
    Path("bizplan.md"),
    Path("bizplan.pdf"),
    cover_name=cfg.get("cover_name"),
    strict=cfg.get("strict", False),
)
```

CLI equivalent: `bubble-bizplan`. See **[Business plans](bizplan.md)**.

### `bubble.paper`

```python
from pathlib import Path
from bubble.paper import build_paper_pdf

build_paper_pdf(Path("paper.md"), Path("paper.pdf"), papersize="a4", two_column=False)
```

CLI equivalent: `bubble-paper`. See **[Academic papers](paper.md)**.

## Utilities

Common helpers in `bubble.utils`:

- `find_project_root()` — locate book repo root
- `load_merged_peanut_config(path)` — merge project + default config
- `run_python_script(...)` — execute figure generators in conda env

Locale helpers in `bubble.locales`:

- `VALID_LANGS`, `get_locale(lang)`, `chapter_md_path(...)`, `book_output_stem(...)`

Geometry and optimization constants in `bubble.book_config`.

## Error handling

`bubble.convert` raises:

- `BuildError` — base class
- `PreprocessingError` — Markdown preprocessing failed
- `CompilationError` — LaTeX/Pandoc failed

Use `BuildMode.CI` in automated pipelines to fail fast on warnings treated as errors.
