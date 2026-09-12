# armymemo — U.S. Army memorandum class for LaTeX

`armymemo.cls` typesets memoranda in the format required by **AR 25-50**
(_Preparing and Managing Correspondence_). You supply the metadata — office symbol,
subject, signature block, distribution — as preamble declarations, and write the body
as an ordinary nested `enumerate`. The class produces the letterhead, the classification
markings, the signature block, and the enclosure/distribution/copies-furnished lists.

## Requirements

- **LuaLaTeX or XeLaTeX.** The class uses `fontspec` and calls `\setmainfont` /
  `\setsansfont` directly, so **pdflatex will not compile it.**
- **Times New Roman and Arial installed system-wide.** Times New Roman is the body font,
  Arial the letterhead font. If either is missing the class falls back to the
  metric-compatible TeX Gyre face and says so loudly — AR 25-50 names the typeface, so a
  silent substitution would hand you a memo that looks finished and is not compliant.
- `latexmk` to drive builds, `chktex` to lint. Both come from TeX Live.
- **Everything else comes from the repo's `Brewfile`:**

  ```sh
  brew bundle                      # install it all
  brew bundle check --no-upgrade   # just check, install nothing
  ```

  That covers `go-task` (the build driver), `poppler` (`pdftotext` and `pdfinfo` — the
  test harness cannot run without them, and TeX Live does **not** ship them), and the
  formatters and linters `task lint` runs. TeX Live itself is not in the Brewfile;
  Homebrew does not manage it.

### Files you need

The class is often copied out of this repository on its own. The full set is:

| File           | When                                                    |
| -------------- | ------------------------------------------------------- |
| `armymemo.cls` | always                                                  |
| `DODb1.pdf`    | always, unless you point `\logo{...}` at your own image |
| `digsig.sty`   | only with the `digsig` class option                     |

Put them beside your document, or anywhere TeX searches. A missing logo is reported by
name with a class error rather than failing inside `graphicx`.

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
task                # build every examples/*.pdf
task test           # rebuild the examples and diff against the golden files
task golden         # recapture the golden files after an intended output change
task check          # chktex armymemo.cls
task lint           # every gating linter: Python, shell, LaTeX
task format         # reformat armymemo.cls and the examples with latexindent
task clean          # remove built PDFs and aux files

cd examples && latexmk -lualatex example.tex     # build one example
```

Builds are driven by [go-task](https://taskfile.dev) (`Taskfile.yml`); `task --list`
prints the current set.

`task test` is the regression check: it extracts the text and page count from every
rendered example and compares them against `examples/golden/`. A class change that is
meant to preserve output should leave it green; one that is meant to change output
updates the goldens with `task golden`, and the resulting diff is the review evidence.

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

| Command            | Purpose                                                                                                                    |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `\address{...}`    | One line of the letterhead address. Repeat, in order, for each line.                                                       |
| `\department{...}` | Departmental line. Defaults to `DEPARTMENT OF THE ARMY`.                                                                   |
| `\logo{...}`       | Letterhead seal, given as a graphics file without extension. Defaults to `DODb1`, the DoD seal AR 25-50 1-16b(1) requires. |

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
| `\addcf{...}`     | Add a copies-furnished entry.                                                         |

The closing block — authority line, enclosures and signature — is typeset as a single
unbreakable box, so it is never split across a page. Distribution and copies-furnished
lists flow normally and may break, but never leave their heading stranded.

`\continuedistro` and `\continuecf` were removed: they required the author to predict
where the page would break and insert a manual `(CONTINUED)` marker. Delete any calls to
them — the class now keeps headings with their entries automatically.

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

Do not subdivide beyond the fourth level. `\st` is provided as a superscript ordinal for
unit designations, as in `501\st\ Legion`; it usually needs a following `\ ` to keep the
interword space. Write the other ordinals as `2\textsuperscript{nd}`.

`\st` is a short, generic name in the global namespace, so a document or package that
defines its own `\st` will collide with it. The companions `\nd`, `\rd` and `\thh` were
removed for that reason -- nothing used them, and `\thh` had to be misspelled because
`\th` (thorn) was already taken.

Typed `"` is **active**. The class calls `\MakeOuterQuote{"}` (csquotes), so an ASCII
double quote opens or closes a typographic pair depending on position -- `"correspondence"`
renders as a left and right curly pair, not two typewriter marks. Two consequences worth
knowing:

- **Nested quotes do not nest.** One active character cannot tell an inner quote from an
  outer one, so csquotes alternates and the inner pair comes out closing-then-opening.
  Use `\enquote{outer \enquote{inner} text}` for anything nested; it produces the correct
  double-then-single pairing.
- **For a literal typewriter quote, write `\textquotedbl`.** It is unaffected by csquotes.

`examples/example-quotes.tex` demonstrates all three cases.

### Class options

`digsig` adds an interactive PDF signature field to the signature block, via the bundled
`digsig.sty`:

```latex
\documentclass[digsig]{armymemo}
```

Any other option is passed through to KOMA-Script's `scrartcl`, which the class builds on.

## Examples

`examples/` holds working documents that exercise the class; each is built by `task`.

| File               | Shows                                                                                                                                                      |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `example.tex`      | The standard memorandum, with distribution and copies furnished.                                                                                           |
| `example-long.tex` | A fully populated memo: long `MEMORANDUM FOR` address, suspense date, classification banner, authority line, enclosure, distribution and copies furnished. |
| `example-grid.tex` | Layout and spacing against a measurement grid.                                                                                                             |
| `example-sig.tex`  | The `digsig` option, with an alternate logo.                                                                                                               |

The table covers the demonstration documents. The rest of `examples/` are regression
fixtures, each added to pin down one behaviour that was previously untested — a wrapping
subject, a single address, a memo with no enclosures, the active `"` character, and so on.
The file's own header comment says what it asserts and which change would move it. `task
test` builds all of them and diffs the rendered text against `examples/golden/`.

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
