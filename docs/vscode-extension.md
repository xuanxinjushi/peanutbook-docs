# VS Code extension

**Peanutbook Preview** is a VS Code extension that builds the active Peanutbook Markdown file with `bubble-convert` and shows the resulting PDF in an in-editor preview panel, rebuilding automatically on save.

It's a thin wrapper around the `bubble-convert` CLI — it does not replace `bubble-build`/`bubble-convert` and requires the `peanutbook` package (with Pandoc and a PDF engine) to already be set up per [System requirements](system-requirements.md).

## Install

The extension isn't published to the Marketplace yet. Install it from a built `.vsix`:

1. Build the package: `cd plugin && npm install && npm run compile && npx vsce package`
2. In VS Code, open the Command Palette → **Extensions: Install from VSIX...** → select the generated `.vsix`.

## Usage

1. Open a Peanutbook `.md` file (a chapter or any standalone Markdown file).
2. Run **Peanutbook: Preview PDF** from the Command Palette, the editor title bar, or the editor context menu.
3. A preview panel opens beside the editor with **Open PDF** / **Rebuild** buttons; saving the Markdown file rebuilds it automatically.

Under the hood it runs:

```bash
bubble-convert <file> --format pdf --engine <engine>
```

from the detected Peanutbook project root (the nearest ancestor containing `peanut.config`).

## Engine choice

`peanutbook.engine` selects the PDF engine passed to `bubble-convert`:

| Engine | Trade-off |
|--------|-----------|
| `typst` (default) | Fast rapid-preview build via Pandoc's native Typst writer; skips headers, trim-size templates, watermarking, and note/figure/equation styling that require the LaTeX Lua filter chain |
| `latex` | Full print-quality LaTeX build — slower, but what `bubble-build`/`bubble-convert` produce for real output |

Switch engines with the **Peanutbook: Select Engine (LaTeX / Typst)** command, or set `peanutbook.engine` directly.

## Settings

| Setting | Default | Purpose |
|---------|---------|---------|
| `peanutbook.converterCommand` | `bubble-convert` | Converter binary. Use an absolute path if `bubble-convert` isn't on `PATH` (common when the install lives in a project-local virtualenv). |
| `peanutbook.engine` | `typst` | `typst` or `latex` — see above. |
| `peanutbook.pandocPath` | *(empty)* | Full path to a Pandoc binary, for portable/non-`PATH` installs. |
| `peanutbook.additionalPathDirs` | `[]` | Extra directories prepended to `PATH` when running `bubble-convert` (portable Pandoc, MiKTeX/TeX Live, qpdf, Ghostscript). |
| `peanutbook.buildTimeoutSeconds` | `300` | Max seconds to wait for the whole `bubble-convert` invocation before the extension kills it. `0` disables the timeout — useful when debugging a genuinely long build. |
| `peanutbook.extraArgs` | `[]` | Extra CLI args appended to `bubble-convert`, e.g. `["--style", "square"]` or `["--lang", "cn"]`. |
| `peanutbook.rebuildOnSave` | `true` | Rebuild an open preview automatically when its Markdown file is saved. |
| `peanutbook.logDiagnostics` | `true` | Log converter candidates, resolved tool paths, `pandoc --version`/`typst --version`, process IDs, elapsed time, and timeout kills to the **Peanutbook** output channel. |
| `peanutbook.showOutputOnBuild` | `true` | Show the output channel automatically when a build starts. |
| `peanutbook.clearOutputBeforeBuild` | `false` | Clear the output channel before each build. |

`peanutbook.buildTimeoutSeconds` bounds the extension's own subprocess (the whole `bubble-convert` call). Independently, `bubble-convert` itself times out and kills each individual Pandoc/LaTeX/Typst step it shells out to — see [`PEANUTBOOK_CHILD_TIMEOUT_SECONDS`](commands/build-convert.md#child-process-timeouts) for that inner timeout.

## Built-in Markdown Preview Integration

In addition to the PDF preview panel, the extension enhances VS Code's built-in Markdown preview (`Ctrl+Shift+V` / `Ctrl+K V`):
- **Live Variable Substitution**: Resolves `@@pb:var_name@@` and `@@pb:author|default@@` placeholders on the fly using `peanut.config`.
- **Peanut Callouts**: Renders `>NOTES:`, `>IMPORS:`, `>WARNS:`, and `>CENTERS:` as styled callout cards in the built-in preview pane.

## Troubleshooting

**Output channel shows a nonzero exit and no clear error** — enable `peanutbook.logDiagnostics` (on by default) and check the **Peanutbook** output channel for the resolved converter/Pandoc paths and the underlying command.

**`bubble-convert` not found** — set `peanutbook.converterCommand` to the full path of the `bubble-convert` executable (e.g. inside a project virtualenv's `Scripts`/`bin` directory).

**`Pandoc not found`** — set `peanutbook.pandocPath` to the Pandoc binary, or add its directory to `peanutbook.additionalPathDirs`.
