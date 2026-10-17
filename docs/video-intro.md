# Video intro and outro cards

Internal notes on the animated intro and outro that `bubble-slides-video` adds to slide videos.
Not in the public docs yet.

## What it looks like

**Intro (4.5 s), before the first slide**

- The logo pops in.
- The book cover slides in from the right with a slight tilt, then floats slowly.
- "CHAPTER N", the chapter title, an amber underline and the site name appear one after another.
- It cross-fades into slide 1.

**Outro (7 s), after the last slide**

- The last slide fades into it.
- The cover comes in from the left.
- "Thanks for watching", the book title, and a pulsing amber "Get the book → math4ai.org" button
  appear, with the logo in the corner.

## Setup

### 1. Requirements

- `node` and a Chrome/Chromium binary. Chrome is found from `$CHROME_PATH`,
  `$PUPPETEER_EXECUTABLE_PATH`, `google-chrome`/`chromium` on the PATH, or the puppeteer cache
  (`~/.cache/puppeteer/chrome/*/chrome-linux64/chrome`).
- marp-cli installed, since its bundled `puppeteer-core` is used. No extra `npm install` is needed.
- Network access for Google Fonts (Inter). Without it the cards fall back to Helvetica/Arial.

### 2. Configure the deck

Add a `video` block to the deck's `peanut.config`:

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

| Key | Meaning |
|---|---|
| `intro`, `outro` | Turn each card on or off. |
| `cover` | Front cover image. Required: without it both cards are skipped. |
| `logo` | Logo image (optional). Its near-white background is blended away. |
| `book` | Book title on the outro. |
| `site` | Shown under the intro title and in the outro button. |
| `cta` | Button text before the site: "Get the book → math4ai.org". |
| `music` | Optional audio file played under the cards only (faded in and out, volume 0.6). |

Paths are relative to the deck folder. The chapter label comes from `book_title`:
`"Math4AI.ORG - Chapter 1: Vector Space and Inner Product"` gives "Chapter 1" and
"Vector Space and Inner Product". A title without "Chapter N: " is shown whole.

All 21 math4ai chapter decks are configured this way.

### 3. Build

```bash
cd chapterN-*/ppt
bubble-slides-video slides.md                  # uses peanut.config
bubble-slides-video slides.md --no-intro       # override per run
bubble-slides-pipeline --all --skip-tts        # rebuild every chapter with existing audio
```

`--intro/--no-intro` and `--outro/--no-outro` work on both `bubble-slides-video` and
`bubble-slides-pipeline`. They are forwarded by `--tts` too. The web "Export Video" button
follows `peanut.config`.

## Implementation

### Files

- `slides_cards.py` (new):
  - `load_card_config()`
  - the `intro_html()` and `outro_html()` templates
  - `render_card()`
  - the embedded frame-capture script (`_FRAMES_JS`)
  - `find_chrome()` and `find_puppeteer()`
- `slides_video.py`: renders the cards, shifts the subtitles and chapters, blends at both ends,
  and adds the cards to the concat list. Also `png_size()` and the `--intro/--outro` options.
- `slides_pipeline.py`: passes `--intro/--outro` through to `build_slides_video()`.

### Rendering a card

1. The template is a 1280×720 HTML page, the same size as a Marp 16:9 slide, styled with the deck's
   fonts and colors (navy `#162d50`, amber `#b45309`). Motion is plain CSS keyframes
   (`pop`, `up`, `fade`, `grow`, `slidein`, `float`, `drift`, `pulse`).
2. A small Node script, written to a temp folder at runtime, opens the page in headless Chrome:
   - The viewport is 1280×720 with `deviceScaleFactor = slide width / 1280`, so the cards match
     the slide images (1920×1080 at the default `--scale 1.5`).
   - All animations are paused at t = 0, and the script waits for fonts and images.
   - For each frame *i*, every animation is set to `currentTime = i / fps` and the page is
     screenshotted.

   The output is deterministic and independent of machine speed: 30 fps × 4.5 s = 135 frames.
3. ffmpeg encodes the PNG sequence with the same settings as the slide clips:
   - video: libx264, yuv420p, `settb=AVTB`
   - audio: AAC 192 kb/s, 44.1 kHz, stereo; silent (`anullsrc`) unless `music` is set

   Because the settings match, the final `-f concat -c copy` join still works.
4. `render_card()` returns the card's last frame as a PNG, which slide 1 blends in from.

### Placing the cards in the video

- **Timing.** The cards are rendered after the per-slide audio is assembled and before the
  subtitles and chapters are written. This is needed because the outro blends from the last
  slide's final frame.
- **Shifted times.** With an intro, `lead = INTRO_SEC`:
  - every subtitle time gets `+ lead`
  - every chapter mark except the first gets `+ lead`; the first stays at `00:00` and covers the intro
- **Intro → slide 1.** This reuses the slide-transition mechanism: slide 1 gets
  `intro_last` as its "previous slide" image, so it fades in during its own lead-in silence and no
  clip gets longer.
- **Last slide → outro.** The outro clip itself starts with an `xfade` from the last slide's final
  frame (`lead_in`, `--transition-sec` long). It is skipped with `--transition none`.
- **Order.** The concat list is `intro.mp4`, then the slide clips, then `outro.mp4`.
- **Failure handling.** If the cards can't be rendered (no node, Chrome or puppeteer-core, or a
  render error), that card is skipped with a warning and the video is still built.

### Tuning

- Lengths: `INTRO_SEC = 4.5` and `OUTRO_SEC = 7.0` in `slides_cards.py`.
- Look and motion: edit the CSS in `intro_html()` and `outro_html()`. Animation delays control the
  order things appear in; the last intro element (the site name) finishes at about 2.4 s.
- To check a layout without a full build, render one card directly:

  ```python
  from pathlib import Path
  from bubble.slides_cards import load_card_config, intro_html, render_card
  c = load_card_config(Path("chapter6-eigendecomp-of-square-matrix/ppt"))
  render_card(intro_html(c), Path("/tmp/intro.mp4"), 4.5, (1920, 1080))  # also writes /tmp/intro_last.png
  ```

### Verified

On a 3-slide Chapter 1 build with the real audio:

- video and audio end together (118.36 s vs 118.38 s)
- the voice starts at 4.85 s, matching its shifted subtitle (4.8 s)
- chapters start at 00:00 and the rest move by 4.5 s
- the longest chapter title (Chapter 6) fits on three lines

## To decide

1. **Intro or title slide?** Each deck's title slide (slide 1) repeats what the intro shows,
   including a cover, so the opening says the same thing twice. Mid-dissolve the two covers
   briefly overlap. Options:
   - keep both (current)
   - hide the title slide when the intro is on. Its narration (the greeting) would then play over
     the intro instead, or the title slide's image would be swapped for the intro's last frame.
   - turn the intro off and rely on the title slide
2. **Music.** The cards are silent unless `video.music` points to an audio file. Choose a
   royalty-free sting (about 5–8 s) that fits both cards, or separate files per card (would need
   a small change: `music_intro` / `music_outro`).
3. **Build time (Cached).** Rendered intro and outro cards are cached per chapter in
   `<deck_dir>/.build/cards/` (ignored by Git). The cache key (`card_cache_key()`) is a
   SHA-256 hash over the generated HTML/CSS template, capture script (`_FRAMES_JS`), resolution
   and frame rate (`size`, `fps`, `seconds`), audio assets (`music` size and mtime), and transition
   inputs (`lead_in`, `lead_in_sec`). Rebuilding a deck reuses cached cards in < 1 ms instead of
   re-rendering (saving ~80 s per chapter). Disable via `--no-card-cache`.
4. **Next:** animated Part I / II / III divider cards (idea 2 in `video-fancy.md`). These replace a
   divider slide's still image with an animated version of the same length, so narration is
   unchanged. They need divider detection: a `## Part ...` heading or the `lead` class.
