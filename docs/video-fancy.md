# Making slide videos more dynamic

Ideas for `bubble-slides-video`, beyond what the video build already does. Not implemented yet.

## Where we are

`slides_video.py` renders each slide with Marp as a still PNG and holds it for the length of the
slide's narration. Slides with `[show: ...]` cues in their speaker notes get one frame per notes
section (the extra decks from `reveal_decks`). ffmpeg `xfade` cross-fades between those frames at
the start of each section's first segment. Animated GIFs are frozen to their last frame. Clips are
joined with a stream-copy concat.

So most of the room left is in **motion** and in **guiding the viewer's eye**.

## Quick wins (hours, reuse what exists)

1. **Transitions between slides.** *Done:* `--transition` (default `fade`) and `--transition-sec`
   (default 0.5) on `bubble-slides-video` and `bubble-slides-pipeline`. The blend plays inside the
   next clip's lead-in silence, so clip lengths, subtitles and chapters are unchanged and the
   stream-copy join still works. Original note: slide changes were hard cuts. A 0.3–0.5 s fade, push or wipe
   (`xfade=transition=fade|slideleft|circleopen|...`) makes the video feel produced.
   *Cost:* the final join can't be `-c copy` any more. Either re-encode the whole video, or overlap
   only the boundaries.
2. **Intro, outro and chapter title cards.** *Intro and outro done* (`slides_cards.py`, `video` block in
   peanut.config); animated Part cards still to do. Original note: A 3–5 s animated opener (logo plus book cover), an
   animated card at each "Part I / II / III" divider slide, and an outro that holds the
   "Get the book → math4ai.org" call to action. These can be pre-rendered once and prepended or
   appended per chapter.
3. **Background music bed.** Low-volume music under the narration, ducked when the voice speaks
   (ffmpeg `sidechaincompress`, or a simple volume envelope from the segment timings we already have).
4. **Progress bar.** [Done] Configurable via `peanut.config` (`video.progress_bar = "bottom" | "top" | "left" | "right" | "none"`) or CLI (`--progress-bar [bottom|top|left|right|none]`, `--no-progress-bar`). A subtle bar along the chosen edge showing position in the lecture, with Part I/II/III boundaries marked by tick marks. Slide durations and part boundaries are computed before encoding, rendered via FFmpeg `drawbox` per clip, and concatenated cleanly with `-c copy`.

## Guiding the eye (medium, builds on `[show:]` cues)

5. **Highlight the element being discussed.** [Done] Configurable via `peanut.config` (`video.highlight = true`) or CLI (`--highlight`, `--no-highlight`). When a section starts, elements revealed earlier are dimmed to 0.45 opacity, while the active element is highlighted with full opacity and a subtle amber glow and outline (`box-shadow` + `outline`). Transitions smoothly between sections via existing reveal cross-fade.
6. **Slow zoom and pan (Ken Burns).** Push gently in on the current element ("look at the figure on
   the right"), then ease back out. ffmpeg `zoompan` or a `crop`/`scale` expression over time.
   *Needs:* each element's bounding box in slide pixels. Get it from one headless-Chrome pass over
   the rendered HTML; the `cues.js` checker in the speaker-notes skill already runs puppeteer
   against the deck.
7. **Animated laser pointer.** A red dot glides to "the left card", "the amber box" and so on as the
   section starts. It uses the same bounding boxes as idea 6, and ffmpeg `overlay` with
   time-interpolated `x`/`y`.
8. **Code that builds up line by line.** [Done] Supports `[show: code 1-4]` or `[show: code 5-8]` (or `[show: lines 2-3]`) in speaker notes. A lightweight custom engine (`marp_engine.js`) wraps code lines in `<span class="line line-N">` while preserving syntax highlighting and pixel-identical layouts. Code lines reveal sequentially in sync with narration via the existing reveal pipeline, and pair seamlessly with `--highlight` (earlier lines dim to 0.45 opacity while the active lines glow with an amber outline).

## Motion in the content (highest value, most work per slide)

9. **Animated figures.** `chapter1/img/vector_anim.py` (the growing vector GIF) is the first example.
   Manim (3Blue1Brown style) or matplotlib animations for the key concepts:
   - Gram–Schmidt: project, subtract, normalize, one vector at a time
   - a matrix transforming the grid; SVD as rotate → stretch → rotate
   - gradient descent zig-zagging down a narrow valley vs. Newton's single jump
   - Langevin particles spreading out; diffusion turning noise into data

   About twenty of these across the book would change the feel a lot. For them to play inside the
   MP4 (not frozen), overlay the GIF or video at the figure's bounding box: hide the `<img>` in the
   screenshot, then use ffmpeg `overlay` with `-ignore_loop 0` and scaling to the box, starting at
   the cue time. Fall back to the frozen frame if measuring the box fails.
10. **Equations built term by term.** Reveal a long derivation one display line at a time. Mostly
    this is finer `[show:]` cues on `p:nth-of-type(n)` equation paragraphs; no new code needed.

## Presence (big effort)

11. **Talking-head avatar.** A lip-synced presenter in a corner, driven by the CosyVoice audio.
    `~/Wav2Lip` and `~/echomimic_v3` are already on this machine. It makes a large difference to
    YouTube engagement, but it is the most GPU-heavy option. Render per slide clip, then
    `overlay` picture-in-picture.
12. **Burned-in captions with word highlight.** For viewers with the sound off. The `.srt` already
    has sentence timing; word-level timing needs forced alignment (e.g. whisperX or
    Montreal Forced Aligner on the segment WAVs).

## Suggested order

1. Ideas 1 and 2. Cheap, and the video immediately looks more professional.
2. Idea 5. The cue data is already there; it adds little code.
3. Idea 9, for the dozen or so concepts that most deserve motion, together with the GIF overlay.

## Caution

In a math lecture, too much motion distracts from the content. Keep every effect subtle and short
(fades ≤ 0.5 s, zooms ≤ 10 %), and use one only when the voice is pointing at something.
