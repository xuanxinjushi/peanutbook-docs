# Chapter Format Standard

This document defines the standard format for all chapters in this book.

## Required Structure

Each chapter markdown file must follow this exact structure at the beginning:

```markdown
# Chapter N: Chapter Title

*Subtitle text in italic*

> Quote text here
- Author Name | Title, Organization, Year

**Code Summary**

- `code_element`: Description of the code element
- `another_code`: Another description
- ... (list 10 most important classes or functions used in the chapter)
```

## Format Rules

1. **Chapter Header** (Line 1):
   - Format: `# Chapter N: Chapter Title`
   - Must start with `#` (H1 heading)
   - Include chapter number and full title

2. **Subtitle** (Line 3):
   - Format: `*Subtitle text in italic*`
   - Single line, wrapped in asterisks for italic
   - Should be a brief, descriptive subtitle

3. **Quote Section** (Lines 5-6):
   - Line 5: Blockquote with `>` followed by quote text
   - Line 6: Author attribution with `-` (dash), format: `- Author Name | Title, Organization, Year`
   - Quote should be inspirational or relevant to the chapter

4. **Code Summary** (Lines 8-19):
   - Header: `**Code Summary**` (bold)
   - List format: `- `code_element`: Description`
   - Use backticks around code elements
   - List approximately 10 most important classes or functions used in the chapter
   - Each item should be concise and descriptive

5. **Main Content** (Line 21+):
   - Regular chapter content starts after the Code Summary section
   - All standard markdown formatting applies

## Example

```markdown
# Chapter 1: Vector Spaces and Inner Products

*From geometric intuition to abstract algebra*

> Mathematics is the art of giving the same name to different things.
- Henri Poincaré | Mathematician, Physicist, 1854-1912

**Code Summary**

- `np.dot()`: Computes dot product of two vectors
- `np.linalg.norm()`: Computes vector norm (default L2)
- `np.outer()`: Computes outer product of two vectors
- `np.cross()`: Computes cross product (3D only)
- `np.inner()`: Computes inner product (generalized dot product)
- `np.angle()`: Computes angle between vectors
- `np.proj()`: Projects one vector onto another
- `np.orthogonal()`: Checks if vectors are orthogonal
- `np.unit_vector()`: Normalizes vector to unit length
- `np.gram_schmidt()`: Performs Gram-Schmidt orthogonalization

## Introduction

The main content of the chapter starts here...
```

## Notes

- The quote and code summary sections are automatically extracted by `bubble-extract-chapter-title` for PDF generation
- Do not modify the structure of these sections after they are set up
- The code summary should reflect the actual content of the chapter
- For chapters that don't use code, you can omit the Code Summary section or list mathematical concepts instead

## Integration with Build System

The chapter format is processed by:
- **`bubble-extract-chapter-title`**: Extracts the title, subtitle, quote, and code summary to generate chapter title pages
- **`bubble-convert`**: Uses the extracted information when converting chapters to PDF
- **`bubble-build`**: Includes the chapter title pages when building the complete book

See the [Quick start](quickstart.md) for information on how to use the build system.
