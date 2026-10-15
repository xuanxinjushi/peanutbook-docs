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

### Speaker Notes for Narration

Speaker notes are written inside HTML comments `<!-- ... -->`. When generating audiobook tracks or lecture videos, Peanutbook's segmenter automatically extracts the speaker notes and sends them to the configured TTS engine (such as CosyVoice or Edge-TTS) to synthesize narration per slide.

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

```bash
# Standard slide build command (defaults to 1080p)
bubble-slides slides.md --format mp4

# Dedicated high-performance video command with custom parameters
bubble-slides-video slides.md --scale 1.5 --fps 30 --workers 8 -o out/lecture.mp4
```

#### CLI Options for `bubble-slides-video`

| Option | Default | Description |
|---|---|---|
| `markdown` | `slides.md` | Path to the presentation Markdown file |
| `-o, --output` | `out/<name>.mp4` | Destination path for the master MP4 |
| `--scale` | `1.5` | Image scale factor (`1.5` = 1080p Full HD, `3.0` = 4K Ultra HD) |
| `--fps` | `30` | Video frame rate |
| `--workers` | `4` | Number of parallel FFmpeg worker threads |
| `--reader` | `notes` | Narration source: `notes` (speaker notes) or `slides` (slide text) |
| `--silence` | `5.0` | Default duration (seconds) for slides without narration |
| `--pad-start` | `0.3` | Visual pause (seconds) before voiceover begins |
| `--pad-end` | `0.5` | Visual pause (seconds) after voiceover ends before transition |

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
