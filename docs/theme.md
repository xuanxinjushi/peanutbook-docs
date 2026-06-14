# Theme (Layer A)

**Theme** lets authors customize Peanutbook look-and-feel **without editing LaTeX**. Define colors, chapter opener style, title sizes, and quote decoration in JSON.

## Where to put it

**Option 1 — standalone file** (recommended for design-focused projects):

```bash
cp $(python -c "import bubble, os; print(os.path.join(os.path.dirname(bubble.__file__), 'peanut.theme.json.example'))") ./peanut.theme.json
```

**Option 2 — inline in `peanut.config`:**

```json
{
  "book_title": "My Book",
  "theme": {
    "colors": { "primary": "#0066CC", "accent": "#99CCFF" },
    "chapter_opener": "square",
    "chapter_title_size_pt": 22,
    "quote_style": "line_only"
  }
}
```

If both exist, keys in `peanut.config` → `theme` **override** the same keys in `peanut.theme.json`.

## Precedence

| Priority | Source |
|----------|--------|
| 1 (lowest) | `peanut.config.default` |
| 2 | `peanut.theme.json` |
| 3 | `peanut.config` → `theme` block |
| 4 | `peanut.config` top-level keys (e.g. `chapter_style`) |
| 5 (highest) | CLI (`--style`, `--main-font`, …) |

Top-level `chapter_style` in `peanut.config` overrides `theme.chapter_opener`. If you only set `chapter_opener` in theme, it replaces the packaged default `circle`.

## Theme keys

### `colors`

| Key | Maps to | Example |
|-----|---------|---------|
| `primary` | `chapterblue` (headings, links) | `"#0066CC"` |
| `accent` | `chapterbluelight` (rules, highlights) | `"#99CCFF"` |
| `muted` or `gray` | `chaptergray` (secondary text) | `"#808080"` |

Hex `#RGB` or `#RRGGBB`.

### `chapter_opener`

Same as `--style` / `chapter_style`: `circle`, `square`, or `none`.

Controls the chapter number decoration on the **chapter title page** (quarter-circle, blue square, or plain).

### Font sizes (no `enable_peanut_font_settings` required)

When set in theme, these apply to `@@...@@` placeholders automatically:

| Theme key | Effect |
|-----------|--------|
| `chapter_title_size_pt` | Chapter title on opener page |
| `chapter_title_leading_pt` | Baselineskip for chapter title |
| `chapter_number_on_title_size_pt` | Large chapter numeral on opener |
| `chapter_number_on_title_leading_pt` | Baselineskip for chapter numeral |
| `chapter_quote_size_pt` | Epigraph quote text |
| `chapter_quote_leading_pt` | Baselineskip for quote |

Explicit top-level keys in `peanut.config` (e.g. `chapter_title_font_size_pt`) override theme.

### `quote_style`

Epigraph decoration on the chapter opener (above the quote text):

| Value | Appearance |
|-------|------------|
| `line_and_bubble` | Horizontal rule + circle (default) |
| `line_only` | Rule only |
| `minimal` / `none` | No decoration |

## Full example

```json
{
  "theme": {
    "colors": {
      "primary": "#1A5276",
      "accent": "#AED6F1",
      "muted": "#666666"
    },
    "chapter_opener": "square",
    "chapter_title_size_pt": 22,
    "chapter_title_leading_pt": 28,
    "quote_style": "line_only"
  }
}
```

## Build

Theme is applied when you run:

```bash
bubble-convert 1
bubble-build --style square
```

No extra flags. Inspect the generated LaTeX header in the build log temp directory if debugging.

## Limits (today)

Theme does **not** yet change:

- Full `chaptertitlepage` layout (move title block, hide Code Summary) — use a custom `templates/*.tpl` override
- New chapter opener shapes beyond circle / square / none
- Cover art — use `cover/` scripts

See [Covers & templates](covers-templates.md) for template-level customization.
