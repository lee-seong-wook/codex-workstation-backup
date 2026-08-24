---
name: book-scan-to-latex
description: Use when a user wants scanned textbook, lecture-note, or book-chapter page images converted into a single LaTeX file that preserves source page boundaries, moves in-page figures to separate image placeholders, and compiles cleanly in Overleaf or local LaTeX.
---

# Book Scan To LaTeX

## Use When

- The input is an ordered set of page images such as `.jpg` or `.png`.
- The user wants a real LaTeX transcription, not a PDF made from pasted page screenshots.
- The final PDF should keep one output page per source image.
- Figures inside the pages will be captured separately and inserted from paths like `figures/ch6/FIG01.png`.
- The pages mix prose, math, tables, and code, especially Korean text plus code comments.

## Workflow

1. Inventory the source pages first.
- Sort the page images by filename.
- Count them before editing. The final PDF page count must match this number.
- Decide the figure directory up front, usually `figures/chN`.

2. Start from a LaTeX scaffold that is safe on Overleaf.
- Use Unicode-safe packages such as `kotex`, `amsmath`, `graphicx`, `caption`, `hyperref`, and `float`.
- For code blocks that may contain Korean comments, prefer `fvextra`/`Verbatim` with a custom environment such as `codeblock`.
- Avoid `lstlisting` when the code block contains Korean or mixed Unicode text; it is a common Overleaf failure point.
- Define a single `\chapterfigdir` macro and route all figure paths through it.

3. Transcribe page by page in source order.
- Preserve headings, numbered equations, tables, lists, and code structure.
- Keep figure captions in the main text, but replace the in-page figure itself with a `\bookfigure{..}{caption}{label}` placeholder at the matching position.
- Insert `\sourcepagebreak` only at real source-page boundaries.
- Do not optimize layout yet; finish the full pass first.

4. Compile and align page boundaries.
- Compile once the full chapter is transcribed.
- Compare `source image count` against `final PDF page count`.
- If the PDF has too many pages, one source page was split. Find the surrounding boundary and remove or move the wrong `\sourcepagebreak`.
- If the PDF has too few pages, two source pages were merged. Add or move a `\sourcepagebreak`.
- Use quick image or PDF inspection to compare the source page content with the generated page content around the mismatch.

5. Finalize the Overleaf-ready version.
- Keep figure placeholders compilable even before the images are uploaded.
- Make the figure macro tolerant to `FIG01.png` vs `FIG1.png`; mixed case fallbacks such as `FIg1.png` are also worth supporting if the user uploads inconsistent names.
- Recompile from scratch after page-boundary fixes.
- Remove temporary contact sheets or rendered comparison images.

## Preferred Macro Pattern

Use a pattern like this when the document needs separate figure uploads and Korean-safe code blocks:

```tex
\DefineVerbatimEnvironment{codeblock}{Verbatim}{
  breaklines=true,
  breakanywhere=true,
  fontsize=\small,
  frame=single,
  framesep=5pt,
  xleftmargin=10pt,
  xrightmargin=10pt
}

\newcommand{\sourcepagebreak}{\clearpage}
\newcommand{\chapterfigdir}{figures/ch6}

\newcommand{\includechapterfigure}[2]{%
  \begingroup
  \edef\chapterfignum{\number\numexpr#1\relax}%
  \IfFileExists{\chapterfigdir/FIG#1.png}{%
    \includegraphics[width=#2]{\chapterfigdir/FIG#1.png}%
  }{%
    \IfFileExists{\chapterfigdir/FIG\chapterfignum.png}{%
      \includegraphics[width=#2]{\chapterfigdir/FIG\chapterfignum.png}%
    }{%
      \IfFileExists{\chapterfigdir/FIg#1.png}{%
        \includegraphics[width=#2]{\chapterfigdir/FIg#1.png}%
      }{%
        \IfFileExists{\chapterfigdir/FIg\chapterfignum.png}{%
          \includegraphics[width=#2]{\chapterfigdir/FIg\chapterfignum.png}%
        }{%
          \fbox{%
            \parbox[c][0.18\textheight][c]{0.85\textwidth}{%
              \centering Missing figure placeholder
            }%
          }%
        }%
      }%
    }%
  }%
  \endgroup
}

\newcommand{\bookfigure}[4][0.75\textwidth]{%
  \begin{figure}[H]
    \centering
    \includechapterfigure{#2}{#1}
    \caption{#3}
    \label{#4}
  \end{figure}
}
```

## Validation Checklist

- `source image count == final PDF page count`
- `figure placeholders compile before images exist`
- `figure directory matches the uploaded Overleaf tree`
- `lstlisting` is not used for Korean code comments
- temporary debug images are deleted before handoff

## Output

The final deliverable should usually be:

- one `.tex` file for the chapter
- optional compiled `.pdf` for verification
- a short note telling the user which figure directory is configured and whether `XeLaTeX` is required
