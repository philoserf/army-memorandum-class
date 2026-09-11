# Changelog

---

## [Unreleased]

### Changed

- **The build is driven by `Taskfile.yml` (go-task 3) instead of `Makefile`, which is
  removed.** Targets map one-for-one -- `make test` is `task test`, and the bare default
  still builds every example -- so the only change for a reader following the README is the
  command name. Three differences are not cosmetic and are worth knowing before trusting a
  green run. **Up-to-date checks are by checksum, not mtime**: `touch armymemo.cls` no
  longer forces a rebuild, though a real edit still does. **`task check` exits 201, not
  chktex's own 2**, because go-task reports a failed command with its own status; nothing
  scripts on it, since the ratchet in `tools/run-tests.sh` invokes `chktex` itself, but do
  not assert on 2. **The build is serial** where the Makefile asked for `-j4`: that bound
  existed because examples built under unlimited parallelism can race on a cold luaotfload
  font-names cache, and a `for` loop in `cmds:` is strictly safer at the cost of wall clock
  (about 55s cold for twenty examples). The hazard is recorded in the `build` task so the
  bound is not reintroduced as unbounded `deps:` fan-out.

  Per-example incrementality is preserved rather than flattened: `armymemo.cls` and
  `digsig.sty` are `sources:` of a per-example `build:one` task, so editing either rebuilds
  all twenty PDFs while editing one `.tex` rebuilds exactly one. That is the #12/#38 fix,
  and collapsing the loop into a single coarse task would silently restore the bug it
  closed. `tools/run-tests.sh` still drives `latexmk` directly and never invokes the
  Taskfile, exactly as it never invoked the Makefile.

### Added

- **`task lint` covers the repository's own tooling.** `chktex` lints the class; nothing
  previously looked at the Python and shell that build and test it. The task runs `ruff`
  (through `uvx` -- it is deliberately not installed) plus `shellcheck` and `shfmt -d`.
  Rule selection lives in `ruff.toml`. `.editorconfig` exists so that a bare `shfmt` agrees
  with the checked-in formatting: shfmt reads `.editorconfig` only when given no formatting
  flags, and without the file a bare `shfmt -w` would rewrite `tools/run-tests.sh` to tabs
  and flatten every `case` arm.

  One ruff finding is suppressed by configuration rather than fixed. AR 25-50 prints en
  dashes in its own figure captions and in its title, so `tools/extract-ar-figures.py` must
  contain real en dashes in both its caption regex and its default path; `RUF001` flags each
  as a confusable. `allowed-confusables` accepts the two dash characters and leaves the rule
  live for everything else. Rewriting them to hyphens breaks caption matching against the
  regulation.

- **`references/`, an ignored directory with a tracked index.** AR 25-50's specimen figures
  are 96 dpi screenshots, so `pdftotext` recovers their captions and nothing else -- and
  those pictures are the only place the regulation states its vertical spacing (figure 2-1
  numbers the blank lines between elements down its left gutter) and its subparagraph
  indents. `tools/extract-ar-figures.py` pulls all 60 out, named from each page's own
  caption so a repaginated reissue still yields correct names. `references/README.md` is the
  only tracked file there: it records what the figures can and cannot settle, how to check
  the local copy is still current, and which further publications are worth fetching.

---

## [0.4.0] - 2026-09-11

### Fixed

- `\mfr` and the no-memo-line default path are covered by the harness. Neither was reachable
  from any example: `\mfr`'s only occurrence in the tree was inside a `%` comment
  (`examples/example-grid.tex:34`), and every example set a memo line explicitly, so
  `\am@memoline`'s three-deep `\ifdefvoid` default -- the branch that supplies
  `MEMORANDUM FOR RECORD` to an author who declares nothing -- never ran. Fourteen goldens
  contain that string, which made the path look covered; all fourteen get it from a literal
  `\memoline{MEMORANDUM FOR RECORD}` typed into the example. This mattered because 0.4.0
  repointed `\mfr` at the newly canonical `\memoline` and the suite would have stayed green
  had that been wrong. Two examples are added rather than one: `example-nomemoline.tex`
  declares nothing and reaches `\mfr` through the default branch at `\AtEndDocument`, while
  `example-mfr.tex` calls `\mfr` from the preamble, so the `\listadd` happens before
  `\begin{document}`. Only timing distinguishes the routes, and a change that made `\mfr`
  safe in one context but not the other would pass with a single example. Both bodies are
  worded identically so a divergence between the routes shows up as a difference between
  the goldens; today they render the line at the same position. Verified by mutation:
  emptying `\mfr` fails exactly these two examples and leaves the other nineteen passing.
- Two guards that could never fire now do. `\ifstrempty` detokenizes its argument without expanding it, so `\ifstrempty{\am@documentmark}` tested the 16-character string `\am@documentmark` — never empty — and both guards always took their non-empty branch. `\documentmark{}` therefore drew two empty TikZ nodes on every page instead of nothing, and the suspense-date block's spacing applied to every memo whether or not it had a suspense date. Both now use `\ifdefempty`. `\suspensedate` additionally stores its raw value in `\am@suspensedate@raw`, because `\am@suspensedate`'s body is a *conditional* rather than the value, so no emptiness test applied to it can ever succeed — the split is load-bearing, not cosmetic. **Rendered output is byte-identical across all 16 examples**: the dead branch emitted `\vspace{-2\baselineskip}`, a near-empty line and `\vspace{\baselineskip}`, which cancelled to zero. The repair is structural, and the guards were verified live by probe (a memo with no suspense date now skips the block; one with a mark still draws it).
- A missing letterhead logo is now reported by name instead of failing inside `graphicx`. The class is frequently copied out of its repository on its own, where the bundled `DODb1.pdf` is simply absent; the result was a bare ``File `DODb1' not found`` naming neither the class nor the remedy. `\am@findlogo` probes first and raises a class error naming the file and pointing at `\logo{...}`. It walks graphicx's own `\Gin@extensions` rather than a hard-coded copy, because `\IfFileExists` performs no extension search and probing the bare name alone would have fired the error on the class's own default (`\logo` defaults to `DODb1`; the file is `DODb1.pdf`).
- A SUBJECT long enough to wrap no longer overflows the continuation-page header. `geometry` reserved a fixed `headheight=2\baselineskip` while AR 25-50 requires the office symbol and the *full* subject on every continuation page, so a wrapping subject wanted three lines in a two-line box -- `Overfull \vbox (14.49998pt too high)`, exactly one line. The overflow grew the head *upward*, pushing it off the 1in top margin and toward the classification marking, rather than down. `\am@fitheadheight` now measures the head at `\AtEndPreamble` -- still the preamble, so `\geometry` is legal, but late enough that `\officesymbol` and `\subject` are both set in either order -- and asks `geometry` for the whole number of lines it needs. The head's top stays on the 1in margin and the body starts a line lower, which is what a two-line subject genuinely costs. Documents whose subject fits on one line are untouched.
- The closing block no longer splits across a page break. The authority line, enclosure list and signature block are now assembled inside a `\parbox`, so the page builder can measure them and either fits the whole closing on the page or moves all of it. Previously the signature was drawn as a zero-height `tikz` overlay at absolute page coordinates: because it occupied no vertical space, LaTeX could not break around something it could not measure, and the enclosure list -- flowing normally at the left margin -- merely happened to land beside it. That single decision produced a `DISTRIBUTION:` heading stranded alone at the foot of a page with its entries overleaf, an enclosure list split mid-list, and, with no enclosures at all, `DISTRIBUTION:` printed on the *same line* as the signer's name. `DISTRIBUTION` and `CF` are deliberately left outside the box, because a `\parbox` cannot break across a page and those lists legitimately need to; they are instead held to their headings by `\Needspace*`, which reserves the heading plus two entries. The undocumented `-10pt` offset the source could not explain is gone -- the box has a natural height.
- The signature block no longer emits a bare comma when a field is missing. `\author`, `\rank` and `\branch` now report themselves and substitute a visible red placeholder, the same way `\officesymbol` and `\subject` already did; previously all four signature fields defaulted to empty and the block rendered a blank line, a line containing only `,`, and another blank line, with no diagnostic at all. The comma between rank and branch is now conditional, so `\branch{}` renders `CPT` rather than `CPT,`. `\title` remains optional -- a memo may genuinely have no duty title.
- A memorandum supplying exactly one `\address` now renders that one line. It previously had three placeholder lines appended to it -- `ORGANIZATIONAL NAME/TITLE`, `STANDARDIZED STREET ADDRESS` and `CITY, STATE 12345-1234` -- producing a four-line letterhead that began with the real address and continued with boilerplate, silently, in the most prominent part of the page. Supplying no address still yields the three placeholders, unchanged.

### Removed

- **`\nd`, `\rd` and `\thh` are removed. This breaks any document that uses them** -- a memo
  written as `2\nd Battalion` will stop compiling, and the fix is `2\textsuperscript{nd}`.
  They were superscript-ordinal shorthands with no call site anywhere in this repository, and
  each one spent a short, generic name from the global namespace to save three characters;
  `\thh` could not even have the name it wanted, because `\th` is thorn. `\st` is kept: it has
  real uses, and unit designations like `501\st\ Legion` are the case the shorthands were
  written for. The collision risk is reduced, not eliminated, and the README now says so
  rather than advertising the family as a convenience.
- `\continuedistro` and `\continuecf` are removed. They inserted a literal `(CONTINUED)` entry followed by `\clearpage` and a repeated heading, so the author had to predict, by hand, where the page would break -- and when the prediction was wrong the output carried a spurious `DISTRIBUTION:` / `(CONTINUED)` pair and an unnecessary page. The redesigned closing keeps a heading with its entries automatically, which is what these macros were manually approximating.

### Changed

- The active `"` character is documented and covered by a test. The class calls
  `\MakeOuterQuote{"}` (csquotes), which makes `"` **active in every document built with this
  class** and silently converts a typed ASCII quote into a typographic one. Nothing in the
  README said so, and nothing tested it: the only `"` characters in the repository sat inside
  `%` comments, where csquotes never sees them, so the behaviour was invisible from both
  directions. `examples/example-quotes.tex` is added as the sole witness -- `pdftotext`
  extracts U+201C/U+201D as distinct bytes from U+0022, so the golden genuinely asserts the
  conversion rather than merely appearing to. Writing the example surfaced a limitation worth
  documenting on its own: **nested quotes do not nest.** A single active character cannot
  distinguish an inner quote from an outer one, so csquotes alternates and the inner pair
  renders closing-then-opening; `\enquote{outer \enquote{inner}}` is the correct route and
  produces proper double-then-single pairing. `\textquotedbl` remains available for a literal
  typewriter quote. The behaviour itself is unchanged -- this is documentation and coverage
  for something that was already shipping.

- The letterhead's line pitch is documented where it is actually set, and the misleading declared leading is gone. `\am@do@address` asked for 8pt type on a 5pt baseline, which taken at face value would overlap the glyphs badly; it did not, because that number never reached the page. The real mechanism is `\setstretch{0.7}`: it scales every declared `\baselineskip` to 0.7x, putting the letterhead's leading below the height-plus-depth of the lines being set, so TeX abandons `\baselineskip` and inserts `\lineskip` glue instead. The pitch is therefore height + depth + `\lineskip` — which is why the gaps differ (11.54pt after the 10pt DEPARTMENT line, 10.11pt between the 8pt address lines) and match nothing the source declares. Contrary to the issue, `\setstretch{0.7}` is **not** inert: deleting it moves the address pitch to 14.45pt. It is load-bearing by accident, and now says so. The declared leading is written equal to the type size, the conventional "no special leading" idiom, instead of a specific-looking number inviting someone to tune something that does nothing. No rendered output changes. AR 25-50 prescribes no letterhead geometry — 1-16 delegates it to a template on APD's website and 1-19 only recommends 12pt generally — so there is no regulation figure to target and the current geometry is preserved deliberately.
- `\parindent` is now set to `0pt` explicitly, and eight `\noindent` calls that no longer earn their keep are gone. The class had been relying on a side effect of another package for a decision of its own: `\RaggedRight` (ragged2e) assigns `\parindent\RaggedRightParindent`, which is zero, so the indent was already suppressed document-wide — measured at 12pt when the class loads and 0pt in the document body. Removing `\RaggedRight` would silently restore a 12pt indent on every paragraph an author starts; the explicit setting is what stops that. Six `\noindent` calls remain because they force *horizontal mode* rather than suppress an indent — deleting the one before `\rlap` in the signature block demonstrably moves `example-sig`'s output. No rendered output changes. `examples/example-multipara.tex` is added as the regression witness: a continuation paragraph inside a body item is the only paragraph in a memo the class does not start itself, so it is the only place a stray `\parindent` could reach the page.

- There is now one documented way to add a memorandum line, and the class and the README agree
  about what it is. `\memoline` and `\addmemoline` were the same command, and the two documents
  each described a different half of the API: the README's table listed `\mfr`, `\memoline`,
  `\multimemofor` and `\multimemothru` and never mentioned `\addmemoline`, while the class's
  own 24-line comment block documented `\addmemoline` and `\multimemothru`, never mentioned
  `\multimemofor`, and closed by apologising that its "example 4 deviates from examples 1-3".
  The examples split along the same line. `\memoline` is now canonical -- it holds the
  `\listadd` and is what `\mfr` calls -- and `\addmemoline` is a retained alias so existing
  documents keep working, deliberately **without** a deprecation warning, which would fire at
  documents that are not broken and churn the `.diag` goldens for no user benefit. The comment
  block is rewritten to match the README, and records that a THRU memorandum needs only
  `\multimemothru` plus `\multimemofor`; the hand-built `\memoline{FOR ...}` form still works
  but is a literal line like any other, not a second supported route. **No rendered output
  changes** -- the substitution is exact, and all 17 goldens are byte-identical. CLAUDE.md's
  Architecture section is corrected in the same change: it named `\addmemoline` as the list
  entry point and claimed every list keeps a counter, which has been false since the counters
  were removed and only `am@encl@count` survived.

- Classification markings are now drawn from the LaTeX kernel's `shipout/background` hook, and the `background` package is no longer loaded. It was pulled in solely to mean "run this on every page"; the kernel has had a hook for exactly that since 2020-10-01, and `\am@classmark` already did all the positioning, so the package earned nothing. The pair it replaces also stated two contradictory intentions -- the package option `pages=all` says every page while `\BgThispage` means this page only. Marks are unchanged: verified byte-identical in position on every page of all fifteen examples via `pdftotext -bbox`.
- **`\NeedsTeXFormat` now requires a 2020-10-01 kernel**, which the `shipout/background` hook needs. It also now precedes `\ProvidesClass`, the canonical order -- the format check should run before anything else.
- The classification mark's distance from the paper edge no longer depends on the ambient font size. The marks are positioned against `\paperwidth`/`\paperheight` with `inner sep=0pt`; TikZ's default inner sep is `0.3333em`, so the padding -- and with it the mark's offset -- silently followed whatever font size was current where the node happened to be built.
- Class options are now declared and processed before `\LoadClass`, the canonical LaTeX2e order. They were processed 140 lines after it, which left `\DeclareOption*{\PassOptionsToClass{...}{scrartcl}}` forwarding options to a class that was already loaded; that dead line is removed. No behaviour changes: user options reached `scrartcl` through the kernel's global-option rule before and still do, and `[digsig]` never depended on the pass-through. The `\LoadClass` options now carry a comment recording that 12pt and oneside are AR 25-50 requirements and deliberately not overridable.
- Nesting a list past the fourth level now reports the rule it breaks instead of crashing. AR 25-50 prohibits subdividing beyond the third subdivision, and the class implements four levels; it previously *declared* nine, so a fifth level died with an `enumitem` "Undefined label" error that never mentioned the regulation. A fifth level now prints a red `[AR 25-50]` marker and emits a class warning naming the rule, once per offending item, and the document still builds.
- Font selection now probes with `\IfFontExistsTF` and falls back to the metric-compatible TeX Gyre Termes / TeX Gyre Heros when Times New Roman or Arial is missing, emitting a loud class warning. Previously the class selected both unconditionally, so a machine without the non-free fonts produced no PDF at all -- a total failure, not a degraded one. The warning is deliberate: AR 25-50 is the specification, so a silent substitution would hand the author a memo that looks finished and is not compliant.

---

## [0.3.0] - 2026-03-29

### Added
- `[digsig]` class option: enables an interactive PDF digital signature field in the signature block, positioned above the signer name line and aligned to the signature block indent
- Bundled `digsig.sty` v2.3 (2022-03-31, MIT, Martin Lottermoser) -- provides `\digsigfield` macro via hyperref extension
- `examples/digsig.sty` symlink so examples compile without TEXINPUTS changes
- `examples/example-sig.tex` -- new example demonstrating the `[digsig]` option with a custom logo
- `\enclsnocount`: new command for unnumbered enclosure list (AR 25-50 Figure 4-4)

### Fixed
- `SUBJECT:` line now uses double-space per AR 25-50 1-17
- Added `\brokenpenalty=10000` to prevent hyphenation across page breaks

### Changed

- Removed `\frenchspacing` -- 4 OCT 24 update: 1-39.b.(9) two spaces after
  sentences. *The space between sentences in LaTeX is stretchy anyway, and
  there's hardly any visible difference between the two. This restores the
  default behavior.* See discussion: https://tex.stackexchange.com/q/4705
- 4 OCT 24 update: 1-19. Leaders can direct fonts and formatting. -- Font
  default changed from Arial to Times New Roman Following IG guidance for Army
  Senior leaders (below). Can be overridden by placing `\setmainfont{Arial}` in
  the preamble.  As cited at  https://ig.army.mil/Portals/101/Documents/IG%20Training%20Documents/DAIG_2025%20Correspondence%20and%20Reports%20Guide_web.pdf?ver=tD5_JdJC9pYy11ki077Fow%3D%3D

    > As of May 2024, all correspondence addressed to the Top 4 Army Senior leaders (Secretary,
    > Under Secretary, Chief of Staff, and Vice Chief of Staff) will adhere to the standards issued by
    > Executive Communications and Control (ECC). In particular, this includes the use of Times New
    > Roman in all communications (except the letterhead itself, which remains in Arial).

- Refactored `\am@encls` to proper if/else chain

---

## Assets

### DOW-Seal-BW.pdf

- **Fetched:** 2026-03-28
- **Source:** https://www.war.gov/Portals/1/Page-Assets/branding-guide/seals/DOW-Seal-BW.ai
- **Conversion:** `pdftocairo -pdf orig-DOW-Seal-BW.ai DOW-Seal-BW.pdf`
- **Result:** 2.2 MB → 392 KB (stripped embedded JPEG preview and ICC profile)

## Bundled Dependencies

### digsig.sty

- **Version:** 2.3 (2022-03-31)
- **Source:** https://gitlab.mn.tu-dresden.de/nsm/templates/nsm-proposal/-/raw/93a60a51e98b07ed4de3480a5ce1cb034f3e5c86/digsig.sty
- **Author:** Martin Lottermoser
- **License:** MIT (SPDX-License-Identifier: MIT)
- **Purpose:** Provides LaTeX macros for digital signature fields in PDF files via hyperref extension
- **Location:**
  - `/digsig.sty` (canonical copy in repo root)
  - `/examples/digsig.sty` (symlink for example compilation)
