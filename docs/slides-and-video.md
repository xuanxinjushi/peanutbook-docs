# Presentation Slides & YouTube Video Synthesis

Peanutbook includes first-class support for creating, presenting, and exporting **Markdown-first presentation slide decks** via [Marp](https://marp.app), with native support for KaTeX mathematics, speaker notes, synchronized TTS voiceover narration, and **one-click broadcast-quality YouTube video synthesis (MP4)**.

---

## Overview

Slide projects in Peanutbook use `doc_type: "slides"` in `peanut.config` with a primary Markdown presentation file (default: `slides.md`).

Peanutbook compiles slide decks into four distinct formats:

| Format | Output | Description |
|---|---|---|
| **📄 PDF** | `out/slides.pdf` | High-resolution vector slides for printing and distribution |
| **🌐 HTML** | `out/slides.html` | Interactive in-browser presentation with speaker notes |
| **📊 PPTX** | `out/slides.pptx` | Editable Microsoft PowerPoint slides |
| **🎬 MP4** | `out/slides.mp4` | Broadcast-quality 1080p/4K video with voiceover narration, chapters, and subtitles |

---

## Slide Deck Structure (`slides.md`)

Slide decks use standard Marp Markdown frontmatter and horizontal rule separators (`---`):

```markdown
---
marp: true
theme: default
paginate: true
size: 16:9
math: katex
title: "Mathematics for AI"
header: "Math4AI.ORG · Chapter 1: Vector Space"
footer: "Henry Fuheng Wu · 2026"
---

<!-- _class: lead -->

# Mathematics for AI
### Chapter 1: Vector Space & Inner Product

<!--
SPEAKER NOTES:
Welcome to Chapter One of Mathematics for AI. In this lecture, we explore
the dual nature of vectors as algebraic columns and geometric arrows.
-->

---

## Dual Nature of Vectors

- **Algebraic perspective**: Ordered list of numbers: $\mathbf{x} \in \mathbb{R}^d$
- **Geometric perspective**: Directed arrow originating from origin

$$
\|\mathbf{x}\|_2 = \sqrt{\sum_{i=1}^d x_i^2}
$$

<!--
SPEAKER NOTES:
Every vector in machine learning has two identities: an algebraic column of numbers,
and a geometric arrow in Euclidean space.
-->
```

### Speaker Notes & Step-by-Step Reveals (`[show:]`)

Speaker notes are written inside HTML comments `<!-- ... -->`. Beyond voiceover narration synthesis, speaker notes can drive **synchronized, step-by-step visual reveals** in both synthesized YouTube videos (`bubble-slides-video`) and the live in-browser presenter view.

By tagging notes sections with `[show: ...]`, elements or specific lines of code appear in lockstep with the speaker's voice.

#### 1. Code Lines Build Up Line-by-Line (`[show: code ...]`)

On slides containing code blocks, you can reveal and highlight code lines step-by-step as they are described:

```markdown
---
## Matrix Multiplication in Python

```python
A = np.array([[1, 2], [3, 4]])
B = np.array([[5, 6], [7, 8]])
C = A @ B
print("Result matrix:", C)
```

<!--
- STEP 1 [show: code 1-2]:
  First, we initialize the input matrices A and B as two-dimensional arrays.
- STEP 2 [show: code 3]:
  Next, we compute their matrix product using Python's at-operator.
- STEP 3 [show: code 4]:
  Finally, we display the resulting matrix C to the console.
-->
```

##### Supported Code Cue Formats
- **Line ranges**: `[show: code 1-3]`, `[show: lines 4-6]`, `[show: code: 2-5]`
- **Single line**: `[show: code 3]`, `[show: line 5]`
- **Non-contiguous lines**: `[show: code 1-2, 5]`
- **Mixed with slide elements**: `[show: img.diagram, code 3-5, .amber-box]`

##### Visual Effects & Highlighting
- **Seamless layout**: A custom engine (`marp_engine.js`) wraps each code line into `<span class="line line-N">` while maintaining syntax highlighting (`hljs-*` classes) and pixel alignment.
- **Focus Highlighting (`--highlight`)**: When enabled via CLI flag (`--highlight`) or configuration (`video.highlight: true` in `peanut.config`):
  - Previously revealed lines automatically dim to `0.45` opacity.
  - The active line block glows with full opacity and a rounded amber outline (`border-radius: 4px; outline: 2px solid rgba(180, 83, 9, 0.6); box-shadow: 0 0 14px rgba(180, 83, 9, 0.45)`).
- **Smooth transitions**: At the start of each notes section, FFmpeg cross-fades smoothly between the slide frames at the exact audio segment timestamp.

#### 2. General Slide Element Reveals

Any slide element can be revealed progressively using CSS selectors:

```markdown
---
## Machine Learning Pipeline

<div class="card card-data">Data Ingestion</div>
<div class="card card-train">Model Training</div>
<div class="card card-eval">Evaluation</div>

<!--
- [show: .card-data]:
  We begin by collecting and sanitizing raw sensor data.
- [show: .card-train]:
  The training pipeline tunes model weights across GPU clusters.
- [show: .card-eval]:
  Finally, validation metrics determine whether the checkpoint is promoted.
-->
```

---

## One-Click YouTube Video Synthesis (MP4)

Peanutbook's video synthesis engine (`bubble-slides-video` / `slides_video.py`) solves the problem of creating high-quality lecture videos without tedious screen recording or manual video editing.

### How It Works

```
[Markdown Slides (slides.md) + Speaker Notes]
                      ↓
           [Audio Segment Matching]
  ├─ Matches each slide with its voiceover WAV audio
  ├─ Inserts 0.3s visual breathing pause before narration starts
  ├─ Inserts 0.5s pause after narration completes before transition
  └─ Auto-pauses silent / interactive prompt slides (e.g. "Your turn")
                      ↓
         [High-Resolution Marp Export]
  └─ 1080p Full HD (scale=1.5) or 4K Ultra HD (scale=3.0) vector frames
                      ↓
      [Parallel Multi-Threaded FFmpeg Encoding]
  └─ Encodes slide video clips concurrently across CPU cores
                      ↓
            [Stream Copy Concatenation]
  └─ Flawless, instantaneous lossless concatenation (< 1 second)
                      ↓
         [YouTube-Ready Triple Deliverables]
  1. out/slides.mp4              (1080p / 30fps Master MP4)
  2. out/slides_chapters.txt      (Clickable YouTube timestamps)
  3. out/slides.srt              (Closed caption subtitles track)
```

### YouTube Assets Output

In addition to the MP4 video, the synthesis engine automatically generates:

1. **`out/slides_chapters.txt`**: Timestamped chapters extracted from slide titles, formatted for direct copy-pasting into your YouTube video description:
   ```text
   00:00 Mathematics for AI
   01:09 Roadmap & Lecture Objectives
   01:47 Vector Dual Nature: Algebraic Array vs. Geometric Arrow
   ...
   ```
2. **`out/slides.srt`**: Standard SubRip subtitles aligned to the exact start and end speech timestamps for YouTube Closed Captions.

---

## How to Export Videos

### 1. From the Web Presenter View (One-Click)

1. Open the Presenter View in your browser:  
   `http://localhost:1979/books/<book>/present/?file=slides.md&mode=presenter`
2. Click the **🎬 Export Video** button in the top-right toolbar.
3. The button will indicate real-time background encoding progress: `⏳ Rendering (15s)...`.
4. When complete, the button turns to **✅ Download MP4**, allowing direct download of the finished video file.

### 2. From the Web Workspace

1. In the document workspace header, find the **Output Format** dropdown.
2. Select **🎬 MP4 (YouTube Video)**.
3. Click **⚡ Build slides**.
4. Once completed, a completion card displays the video file details, YouTube chapters, and a download link.

### 3. From the Command Line (CLI)

Peanutbook provides three command-line tools for presentation decks, ranging from single-command full-pipeline synthesis to fine-grained stage execution:

```
[ slides.md + Speaker Notes ]
             │
             ▼
   bubble-slides-pipeline ──────────┐
   (TTS + Marp + Video in 1-step)   │
             │                      │
             ├── [ Stage 1: Preflight & Book Resolution ]
             ├── [ Stage 2: TTS Narration Synthesis ]
             └── [ Stage 3: Marp Export & MP4 Encoding ]
                                    │
                                    ▼
                     [ out/slides.mp4 + .srt + chapters.txt ]
```

#### A. All-in-One: `bubble-slides-pipeline` (Recommended)

`bubble-slides-pipeline` executes the entire pipeline in a single command: preflight checks, book resolution, TTS narration synthesis (via the web app or direct worker), and in-process video encoding:

```bash
# 1. Standard one-step run (synthesizes missing narration + renders 1080p MP4)
bubble-slides-pipeline slides.md

# 2. Custom voice and 4K Ultra HD video
bubble-slides-pipeline slides.md --voice spk:xuanxin_narrator --scale 3.0

# 3. Audio only (synthesizes audio/tracks/slides/ without rendering video)
bubble-slides-pipeline slides.md --skip-video

# 4. Video only (render video using existing audio tracks on disk)
bubble-slides-pipeline slides.md --skip-tts

# 5. Force re-synthesis of all segments (fresh takes)
bubble-slides-pipeline slides.md --mode all

# 6. Batch build all slide decks in a repository (e.g. inside ~/math4ai)
bubble-slides-pipeline --all

# 7. Batch build and export all MP4s to a single output folder
bubble-slides-pipeline --all -o ~/videos/
```

> [!TIP]
> If you have not yet run `pip install -e .` in your `usao` environment to install console entrypoints, you can invoke the pipeline module directly:
> ```bash
> python -m bubble.slides_pipeline slides.md
> # Or for batch builds:
> python -m bubble.slides_pipeline --all
> ```

##### Pipeline Stages & Resiliency

1. **Preflight Environment Validation**:
   Checks that `slides.md` and `peanut.config` exist, and verifies that `ffmpeg` and `marp` are installed before making any network requests or synthesizing audio.
2. **Automated Book Slug Resolution**:
   Automatically detects the active shelf book slug from the mount registry (`shelf_mounts.json`, including `~/pb-try/data/`) and `~/shelf` symlinks.
3. **Voice Settings & CSRF-Protected TTS**:
   If `--voice` or `--reader` differs from the book's current configuration, the pipeline updates the book's audio settings and dispatches `POST /audio/generate/` with automatic CSRF token management.
4. **Live Progress Reporting**:
   Displays dynamic terminal progress with slide and segment counts and estimated completion time:
   `[10/33 slides | 24/48 segments] Synthesizing audio... ETA: 45s`
5. **Fault Tolerance & Resumability**:
   - **Network Tolerant**: Automatically retries across brief network drops.
   - **Resumable (`--mode missing`)**: Default mode only synthesizes segments missing from disk. If interrupted, re-running resumes where it left off.
   - **Clean Cancellation**: Pressing `Ctrl-C` cancels the job cleanly while preserving all audio segments synthesized so far.
   - **Worker Direct Fallback**: If the Django web application is offline or the deck is not mounted on the shelf, the pipeline constructs the job locally and submits directly to the TTS worker on port 1980 (probing both `127.0.0.1` and `172.17.0.1`).
6. **Key-Based Audio Matching & Pronunciation Glossaries**:
   Segments are matched by exact audio key rather than raw slide text, guaranteeing that words rewritten by pronunciation glossaries align with their voiceover clips without accidental slide muting.
7. **Non-TTY Headless Safety**:
   Marp image rendering runs with `stdin=DEVNULL`, preventing hangs in cron jobs, CI environments, or background subagents.

##### Multi-Chapter Batch Builds (`--all`)

When working in a multi-chapter book repository (such as `~/math4ai` with 21 chapters):

- **Automatic Discovery**: Discovers all `slides.md` decks under the directory tree (e.g. `chapter1-*/ppt/slides.md` through `chapter21-*/ppt/slides.md`), skipping build artifacts, dotfiles, and cache folders.
- **Natural Sorting**: Automatically sorts decks numerically (`chapter1` -> `chapter2` -> ... -> `chapter10` -> ... -> `chapter21`), avoiding alphabetical sorting pitfalls.
- **Per-Chapter Slug Resolution**: Matches each deck to its respective shelf slug (e.g., `math4ai-1` through `math4ai-21`), ensuring chapter-specific audio settings and glossaries apply properly.
- **Resilient Batch Execution**: By default, one deck failure does not stop the entire overnight batch. At completion, a summary report is printed with statuses and runtimes. Pass `--fail-fast` to halt immediately on any error.
- **Centralized Output Option**: Passing `-o <dir>` exports all completed MP4s as `<slug_or_chapter>.mp4` into that folder.

##### CLI Options for `bubble-slides-pipeline`

| Option | Default | Description |
|---|---|---|
| `markdown` | `slides.md` | Path to presentation Markdown file, or root directory when using `--all` |
| `--all` | `false` | Discover and build all slide decks recursively in natural sort order |
| `--fail-fast` | `false` | In batch mode, halt immediately on first deck error (default: continue and summarize) |
| `--mode` | `missing` | `missing` (synthesize missing segments, resumable) or `all` (fresh takes) |
| `--voice` | `peanut.config` | TTS speaker voice (e.g., `spk:xuanxin_narrator`) |
| `--reader` | `notes` | Narration source: `notes` (speaker notes) or `slides` (slide text) |
| `--scale` | `1.5` | Slide image scale: `1.5` = 1080p Full HD, `3.0` = 4K Ultra HD |
| `-o, --output` | `out/<name>.mp4` | Destination path for the master MP4 (or destination directory with `--all`) |
| `--skip-video` | `false` | Only synthesize voiceover audio (saved to `audio/tracks/`) |
| `--skip-tts` | `false` | Skip TTS synthesis; render video from existing audio on disk |
| `--book-slug` | `auto` | Override auto-detected shelf book slug |
| `--web-url` | `http://localhost:1979` | Django web app URL (or via `$PEANUTBOOK_WEB_URL`) |
| `--worker-url` | `auto` | Direct TTS worker URL (or via `$PEANUTBOOK_TTS_URL`) |
| `--fps` | `30` | Video frame rate |
| `--silence` | `5.0` | Display duration (seconds) for slides without narration |
| `--workers` | `4` | Number of parallel FFmpeg encoding worker threads |
| `--transition` | `fade` | Transition between slides: an FFmpeg `xfade` name (`fade`, `dissolve`, `smoothleft`, `circleopen`, `fadeblack`, ...) or `none` for hard cuts |
| `--transition-sec` | `0.5` | Length of the slide transition, in seconds |
| `--highlight / --no-highlight` | `config` | Focus highlighting: dims earlier elements/lines to 0.45 opacity, outlines active element/code lines |
| `--progress-bar` | `config` | Render a video progress bar along an edge (`bottom`, `top`, `left`, `right`, or `none`) |
| `--card-cache / --no-card-cache` | `true` | Cache rendered intro/outro cards in `.build/cards` to speed up subsequent builds |
| `-v, --verbose` | `false` | Enable verbose debug logging |

---

#### B. Standalone Video Renderer: `bubble-slides-video`

If audio tracks are already synthesized under `audio/tracks/slides/`, you can run `bubble-slides-video` directly:

```bash
bubble-slides-video slides.md --scale 1.5 --fps 30 --workers 8 -o out/lecture.mp4
```

Slides change with a short cross-fade by default. Choose another style with `--transition` (any FFmpeg `xfade` name, such as `smoothleft`, `circleopen` or `fadeblack`), or use `--transition none` for hard cuts:

```bash
bubble-slides-video slides.md --transition smoothleft --transition-sec 0.6
```

The transition plays during the next slide's short lead-in pause, so narration timing, subtitles and chapter marks are unchanged.

##### Intro and outro cards

Add a `video` block to the deck's `peanut.config` to open the video with an animated intro (logo, book cover, chapter title) and close it with an outro (cover, book title, a pulsing call-to-action button):

```json
"video": {
    "intro": true,
    "outro": true,
    "cover": "../../cover/7x10/out/cover_front_v2_small.jpg",
    "logo": "../../logo.png",
    "book": "Mathematics for AI and Machine Learning",
    "site": "math4ai.org",
    "cta": "Get the book",
    "music": ""
}
```

- Paths are relative to the deck folder. Without a `cover`, both cards are skipped.
- The chapter label comes from `book_title` ("Math4AI.ORG - Chapter 1: Vector Space and Inner Product" gives "Chapter 1" and the title).
- `music` (optional) plays under the cards only, faded in and out.
- The intro is 4.5 s and the outro 7 s (`INTRO_SEC`, `OUTRO_SEC` in `slides_cards.py`). Subtitles and chapter marks shift by the intro length; the first chapter stays at 00:00.
- Override per run with `--intro/--no-intro` and `--outro/--no-outro`.
- Cards are HTML pages animated with CSS (`slides_cards.py`), rendered frame by frame in headless Chrome with the puppeteer-core bundled in marp-cli, so `node` and Chrome must be available. They add about a minute to a build. If they cannot be rendered, the video is built without them and a warning is logged.

> [!NOTE]
> `bubble-slides-video` also accepts the `--tts` flag, which transparently forwards execution to `bubble-slides-pipeline`:
> ```bash
> bubble-slides-video slides.md --tts --scale 1.5
> ```

#### C. Vector PDF & Document Formats: `bubble-slides`

For standard document exports (PDF, HTML, PPTX):

```bash
# Standard slide build command (defaults to PDF)
bubble-slides slides.md

# Web presentation HTML
bubble-slides slides.md --format html

# PowerPoint PPTX
bubble-slides slides.md --format pptx
```

---

## Dual-Window Presentation Mode

Peanutbook provides a synchronized dual-window presentation system built on browser `BroadcastChannel`:

- **Audience View** (`mode=audience` or default `/present/`):
  - Clean, full-bleed 16:9 slide projection.
  - Floating HUD (`#audience-hud`) appears only upon intentional mouse movement and fades out automatically during playback.
  - Silent auto-advance when narration finishes without distracting UI overlays.
- **Presenter View** (`mode=presenter`):
  - Current slide view + upcoming next slide preview.
  - Rich speaker notes with adjustable font size.
  - Audio playback controls with speech rate adjustment (0.75× to 2.0×).
  - Auto-advance toggle (`Auto-next`) to automatically switch slides upon narration completion.
  - Wall clock, presentation elapsed timer, and blackout toggle (`b`).

