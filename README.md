# armymemo — U.S. Army memorandum class for LaTeX

`armymemo.cls` typesets memoranda in the format required by **AR 25-50**
(_Preparing and Managing Correspondence_). You supply the metadata — office symbol,
subject, signature block, distribution — as preamble declarations, and write the body
as an ordinary nested `enumerate`. The class produces the letterhead, the classification
markings, the signature block, and the enclosure/distribution/copies-furnished lists.

## Requirements

- **LuaLaTeX or XeLaTeX.** The class uses `fontspec` and calls `\setmainfont` /
  `\setsansfont` directly, so **pdflatex will not compile it.**
- **Times New Roman and Arial installed system-wide.** Both are needed: Times New Roman
  is the body font and Arial is used for the letterhead. A missing font is a hard failure,
  not a substitution.
- `latexmk` to drive builds, `chktex` to lint. [`latexrun`][latexrun] is optional; the
  example Makefile prefers it when present and falls back to `latexmk` otherwise.

[latexrun]: https://github.com/aclements/latexrun

### A note on fonts

The class sets **Times New Roman** as the main font. This follows the 4 OCT 24 update to
AR 25-50 (1-19, leaders may direct fonts and formatting) together with DAIG guidance that
correspondence to Army senior leaders use Times New Roman. Arial was mandated from
2013–2020 and remains the letterhead font.

To use Arial throughout, override it in your preamble:

```latex
\setmainfont{Arial}
```

## Quick start

```latex
\documentclass{armymemo}

\address{Organizational Name/Title}
\address{Standardized Street Address}
\address{CITY, STATE~~12345-1234}

\officesymbol{ABC-DEF-GH}
\memoline{MEMORANDUM FOR RECORD}
\subject{The creation of memos using \LaTeX}

\author{John W. Smith}\rank{CPT}\branch{CY}
\signaturedate{\today}

\begin{document}

\begin{enumerate}
\item This memo is a demo.
\item This item has subparagraphs.
  \begin{enumerate}
  \item A paragraph that is subdivided must have at least two subparagraphs.
  \item So if there is an ``a,'' there must be a ``b.''
  \end{enumerate}
\item Point of contact is the undersigned.
\end{enumerate}

\end{document}
```

AR 25-50 5-10.b requires two spaces between the state and the ZIP code. Write them as
`~~` (two non-breaking spaces) or `\ \ `, as shown above.

## Building

```sh
make                # build every examples/*.pdf
make test           # rebuild the examples and diff against the golden files
make golden         # recapture the golden files after an intended output change
make check          # chktex armymemo.cls
make clean          # remove built PDFs and aux files

cd examples && latexmk -lualatex example.tex     # build one example
```

`make test` is the regression check: it extracts the text and page count from every
rendered example and compares them against `examples/golden/`. A class change that is
meant to preserve output should leave it green; one that is meant to change output
updates the goldens with `make golden`, and the resulting diff is the review evidence.

Add `-pvc` to the `latexmk` invocation for continuous preview while drafting; leave it off
for one-shot builds.

## Command reference

### Required fields

Six fields are required. Each substitutes a visible red placeholder into the output so
a missing value is obvious in the PDF rather than only in the log.

| Field                 | Missing behavior | Placeholder     |
| --------------------- | ---------------- | --------------- |
| `\officesymbol{...}`  | build **error**  | `OFFICE SYMBOL` |
| `\subject{...}`       | build warning    | `DRAFT`         |
| `\signaturedate{...}` | build warning    | `DRAFT`         |
| `\author{...}`        | build warning    | `AUTHOR NAME`   |
| `\rank{...}`          | build warning    | `RANK`          |
| `\branch{...}`        | build warning    | `BRANCH`        |

AR 25-50 requires the signature block, so its three name fields are required too.
`\title` is the exception: a memo may genuinely have no duty title, so it defaults to
empty and reports nothing.

`\subject` takes **one mandatory argument and no optional argument.**

### Letterhead

| Command            | Purpose                                                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `\address{...}`    | One line of the letterhead address. Repeat, in order, for each line.                                             |
| `\department{...}` | Departmental line. Defaults to `DEPARTMENT OF THE ARMY`.                                                         |
| `\logo{...}`       | Letterhead seal, given as a graphics file without extension. Defaults to `DODb1`. `DOW-Seal-BW` is also bundled. |

### Memorandum lines

| Command               | Purpose                                                                  |
| --------------------- | ------------------------------------------------------------------------ |
| `\mfr`                | Shorthand for `MEMORANDUM FOR RECORD`.                                   |
| `\memoline{...}`      | An arbitrary memorandum line.                                            |
| `\multimemofor{...}`  | One recipient in a multi-address `MEMORANDUM FOR`. Repeat per recipient. |
| `\multimemothru{...}` | One `THRU` addressee. Repeat per addressee.                              |

The renderers vary their output between zero, one, and many entries, so a single
recipient and a list are both formatted correctly without further markup.

### Signature block and authority

| Command           | Purpose                                                                                   |
| ----------------- | ----------------------------------------------------------------------------------------- |
| `\author{...}`    | Signer's name. Required.                                                                  |
| `\rank{...}`      | Rank. Required.                                                                           |
| `\branch{...}`    | Branch. Required. Set `\branch{}` to drop it and its comma deliberately.                  |
| `\title{...}`     | Duty title. Optional.                                                                     |
| `\authority{...}` | Authority line above the block, upcased automatically (e.g. `BY ORDER OF THE COMMANDER`). |

### Closing lists

| Command           | Purpose                                                                               |
| ----------------- | ------------------------------------------------------------------------------------- |
| `\addencl{...}`   | Add an enclosure. Repeat per enclosure; the count is generated (`Encl` vs `2 Encls`). |
| `\enclsnocount`   | Suppress the enclosure count, per AR 25-50 Figure 4-4.                                |
| `\adddistro{...}` | Add a distribution entry.                                                             |
| `\continuedistro` | Continue the distribution list onto a new page.                                       |
| `\addcf{...}`     | Add a copies-furnished entry.                                                         |
| `\continuecf`     | Continue the copies-furnished list onto a new page.                                   |

### Marking and dates

| Command              | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `\documentmark{...}` | Classification banner, drawn on every page.  |
| `\suspensedate{...}` | Suspense date, rendered as a bold `S:` line. |

### Body

The body is a relabeled `enumerate`. Four levels are implemented, matching AR 25-50:

| Level | Label |
| ----- | ----- |
| 1     | `1.`  |
| 2     | `a.`  |
| 3     | `(1)` |
| 4     | `(a)` |

Do not subdivide beyond the fourth level. The ordinal shorthands `\st`, `\nd`, `\rd`, and
`\thh` are provided for superscripts, as in `1\st` or `4\thh`.

### Class options

`digsig` adds an interactive PDF signature field to the signature block, via the bundled
`digsig.sty`:

```latex
\documentclass[digsig]{armymemo}
```

Any other option is passed through to KOMA-Script's `scrartcl`, which the class builds on.

## Examples

`examples/` holds working documents that exercise the class; each is built by `make`.

| File               | Shows                                                                                                                                                      |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `example.tex`      | The standard memorandum, with distribution and copies furnished.                                                                                           |
| `example-long.tex` | A fully populated memo: long `MEMORANDUM FOR` address, suspense date, classification banner, authority line, enclosure, distribution and copies furnished. |
| `example-grid.tex` | Layout and spacing against a measurement grid.                                                                                                             |
| `example-sig.tex`  | The `digsig` option, with an alternate logo.                                                                                                               |

`examples/armymemo.cls`, `examples/digsig.sty`, and `examples/DODb1.pdf` are symlinks to
the repository root, so the examples always build against the live class.

## References

### AR 25-50, _Preparing and Managing Correspondence_

The regulation this class implements. Headquarters, Department of the Army, dated
**10 October 2020**, carrying an **administrative revision dated 4 October 2024**.

- [Record page][ar25-50] — the stable link; it survives reissue.
- [Direct PDF][ar25-50-pdf] — convenient, but the filename encodes the revision number and
  changes whenever the regulation is reissued.

Both dates matter when reading this README. The 2020 date is the base publication; the
2024 administrative revision is what drives two of the class's choices. Its Summary of
Change assigns the choice of font size and type, for both letters and memoranda, to Army
senior leaders — following the rescission of DA Memorandum 25–52 — and changes the
requirement from one space after ending punctuation to two.

The first is why the class no longer forces Arial; the second is why `\frenchspacing` was
removed. See `CHANGES.md` for the full rationale.

### DAIG Correspondence and Reports Guide

Department of the Army Inspector General guidance, the source for the Times New Roman
default — see [Resources for Correspondence and Reports][daig]. `CHANGES.md` records the
direct URL of the edition consulted, along with the passage quoted from it.

[ar25-50]: https://armypubs.army.mil/ProductMaps/PubForm/Details.aspx?PUB_ID=1020633
[ar25-50-pdf]: https://armypubs.army.mil/epubs/DR_pubs/DR_a/ARN42124-AR_25-50-007-WEB-13.pdf
[daig]: https://ig.army.mil/IG-SCHOOL-RESOURCES/Resources-for-Correspondence-and-Reports/

## Provenance

This repository is maintained at
[philoserf/army-memorandum-class](https://github.com/philoserf/army-memorandum-class). The
class originated with George Allen and remains under his copyright; see the license below.
Thanks to @jschaf for the `enumitem` list structure and document template, and to
@pconwell, @kjelderg, @nelsonrg, and others who contributed to the original.

## License

    Copyright (c) 2011 George Allen, All rights reserved.

    This program is free software; you can redistribute it and/or modify it under
    the terms of the GNU General Public License as published by the Free Software
    Foundation; either version 2 of the License, or (at your option) any later
    version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
    PARTICULAR PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with
    this program; if not, write to the Free Software Foundation, Inc., 59 Temple
    Place, Suite 330, Boston, MA  02111-1307  USA

The grant above is GPL version 2 **or, at your option, any later version**; the `LICENSE`
file in this repository carries the text of **GPL version 3**, which that grant permits.

`digsig.sty` is a separate work bundled here under its own terms: Copyright (C) Martin
Lottermoser, 2005–2022, **MIT License**. Its notice is preserved in the file itself.
