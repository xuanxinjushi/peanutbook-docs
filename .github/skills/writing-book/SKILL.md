---
name: writing-book
description: 'Write and maintain books with Peanutbook Markdown. Use when planning a book, creating chapters, formatting manuscripts, configuring book projects, adding cross-references, or validating a book build.'
argument-hint: '[book topic or writing task]'
---

# Writing a Book with Peanutbook

## When to Use

Use this skill for book planning and manuscript work in a Peanutbook project or another Markdown-based book repository, including:

- Starting a book or organizing its chapters
- Writing or revising chapter Markdown
- Applying Peanutbook syntax for headings, figures, tables, footnotes, and citations
- Adding cross-references between chapters and sections
- Configuring output formats, metadata, covers, watermarks, or PDF protection
- Building and checking the finished book

## Workflow

1. Inspect the existing project structure and configuration before creating files.
2. Identify the book's audience, purpose, tone, and target output formats.
3. Outline the book as a sequence of chapters with a clear progression. Keep one primary subject per chapter and use headings to make the structure scannable.
4. Create or update the project configuration and book sections using the project's existing naming and ordering conventions. In Peanutbook, use the conventional layout below:

	```text
	chapterx/preface.md       # Preface
	chapter1-topic/chapter1.md
	chapter2-topic/chapter2.md
	chapterx/chapterx.md      # Appendix
	```

	Use `partN.md` inside a chapter folder for a part-opening page when the book is divided into parts. Keep translated files beside their English source, such as `preface_zh.md` or `chapter1_zh.md`.
5. Write the preface before the numbered chapters when the reader needs context about the book's motivation, scope, organization, or intended audience. Write an introduction as the first section of a chapter unless the project's configuration documents a separate introduction file.
6. Draft content in Markdown. Prefer direct, concrete prose, consistent terminology, and short paragraphs. Use Peanutbook extensions when they improve navigation or publication quality.
7. Add stable anchors and cross-references for concepts that readers need to revisit. Check every reference after moving or renaming a section.
8. Add supporting assets such as images, tables, references, and cover files using paths relative to the project and the documented Peanutbook formats.
9. Build the book in each requested output format. Treat warnings about missing references, assets, metadata, or malformed Markdown as issues to resolve.
10. Review the rendered output for chapter order, page breaks, headings, figures, links, table layout, cover appearance, and metadata.
11. Make focused revisions and rebuild until the output is clean.

## Section Templates

Use the project's documented chapter format. A typical preface can begin with:

```markdown
# Preface

*Why this book exists and how to use it*

Explain the motivation, intended audience, scope, prerequisites, and structure of the book.
```

A numbered chapter typically begins with:

```markdown
# Chapter 1: Chapter Title

*Chapter subtitle*

## Introduction

State the chapter's goal and what the reader will learn.
```

An appendix can begin with:

```markdown
# Appendix: Reference Material

Use this section for glossaries, checklists, detailed references, or material useful after the main chapters.
```

For Peanutbook, follow the full [chapter format](https://peanutbook.com/chapter-format/) when using title-page metadata such as subtitles, epigraphs, and code summaries.

## Writing Standards

- Match the voice and vocabulary to the intended readers.
- State the purpose of each chapter early and end sections with a useful transition or takeaway.
- Use examples when explaining an abstract idea or workflow.
- Keep terminology and capitalization consistent across the manuscript.
- Use headings for document structure, not decorative emphasis.
- Preserve the author's voice during revision; change wording only when it improves clarity, accuracy, flow, or correctness.
- Separate factual claims from interpretation and identify sources where appropriate.

## Peanutbook Checks

Before considering a book complete, verify:

- Chapter files are included in the intended order.
- Configuration keys and command options match the installed Peanutbook version.
- Internal links, cross-references, images, and citations resolve.
- Images have useful alternative text and readable dimensions.
- Code blocks, tables, footnotes, and special Markdown extensions render correctly.
- Output metadata, cover, watermark, and PDF protection settings are intentional.
- The generated PDF or HTML has no empty chapters, orphaned headings, broken page breaks, or missing assets.

Use the target repository's documentation as the source of truth for its project structure, chapter format, Markdown extensions, configuration keys, cross-reference syntax, HTML generation, PDF protection, and cover options. If the repository does not document one of these areas, inspect its existing chapters and configuration before inventing a convention.

When working in this documentation repository, validate documentation changes with:

```bash
bash build-site.sh
```
