# Changelog

---

## [Unreleased]

### Fixed

- A missing letterhead logo is now reported by name instead of failing inside `graphicx`. The class is frequently copied out of its repository on its own, where the bundled `DODb1.pdf` is simply absent; the result was a bare ``File `DODb1' not found`` naming neither the class nor the remedy. `\am@findlogo` probes first and raises a class error naming the file and pointing at `\logo{...}`. It walks graphicx's own `\Gin@extensions` rather than a hard-coded copy, because `\IfFileExists` performs no extension search and probing the bare name alone would have fired the error on the class's own default (`\logo` defaults to `DODb1`; the file is `DODb1.pdf`).
- A SUBJECT long enough to wrap no longer overflows the continuation-page header. `geometry` reserved a fixed `headheight=2\baselineskip` while AR 25-50 requires the office symbol and the *full* subject on every continuation page, so a wrapping subject wanted three lines in a two-line box -- `Overfull \vbox (14.49998pt too high)`, exactly one line. The overflow grew the head *upward*, pushing it off the 1in top margin and toward the classification marking, rather than down. `\am@fitheadheight` now measures the head at `\AtEndPreamble` -- still the preamble, so `\geometry` is legal, but late enough that `\officesymbol` and `\subject` are both set in either order -- and asks `geometry` for the whole number of lines it needs. The head's top stays on the 1in margin and the body starts a line lower, which is what a two-line subject genuinely costs. Documents whose subject fits on one line are untouched.
- The closing block no longer splits across a page break. The authority line, enclosure list and signature block are now assembled inside a `\parbox`, so the page builder can measure them and either fits the whole closing on the page or moves all of it. Previously the signature was drawn as a zero-height `tikz` overlay at absolute page coordinates: because it occupied no vertical space, LaTeX could not break around something it could not measure, and the enclosure list -- flowing normally at the left margin -- merely happened to land beside it. That single decision produced a `DISTRIBUTION:` heading stranded alone at the foot of a page with its entries overleaf, an enclosure list split mid-list, and, with no enclosures at all, `DISTRIBUTION:` printed on the *same line* as the signer's name. `DISTRIBUTION` and `CF` are deliberately left outside the box, because a `\parbox` cannot break across a page and those lists legitimately need to; they are instead held to their headings by `\Needspace*`, which reserves the heading plus two entries. The undocumented `-10pt` offset the source could not explain is gone -- the box has a natural height.
- The signature block no longer emits a bare comma when a field is missing. `\author`, `\rank` and `\branch` now report themselves and substitute a visible red placeholder, the same way `\officesymbol` and `\subject` already did; previously all four signature fields defaulted to empty and the block rendered a blank line, a line containing only `,`, and another blank line, with no diagnostic at all. The comma between rank and branch is now conditional, so `\branch{}` renders `CPT` rather than `CPT,`. `\title` remains optional -- a memo may genuinely have no duty title.
- A memorandum supplying exactly one `\address` now renders that one line. It previously had three placeholder lines appended to it -- `ORGANIZATIONAL NAME/TITLE`, `STANDARDIZED STREET ADDRESS` and `CITY, STATE 12345-1234` -- producing a four-line letterhead that began with the real address and continued with boilerplate, silently, in the most prominent part of the page. Supplying no address still yields the three placeholders, unchanged.

### Removed

- `\continuedistro` and `\continuecf` are removed. They inserted a literal `(CONTINUED)` entry followed by `\clearpage` and a repeated heading, so the author had to predict, by hand, where the page would break -- and when the prediction was wrong the output carried a spurious `DISTRIBUTION:` / `(CONTINUED)` pair and an unnecessary page. The redesigned closing keeps a heading with its entries automatically, which is what these macros were manually approximating.

### Changed

- `\parindent` is now set to `0pt` explicitly, and eight `\noindent` calls that no longer earn their keep are gone. The class had been relying on a side effect of another package for a decision of its own: `\RaggedRight` (ragged2e) assigns `\parindent\RaggedRightParindent`, which is zero, so the indent was already suppressed document-wide — measured at 12pt when the class loads and 0pt in the document body. Removing `\RaggedRight` would silently restore a 12pt indent on every paragraph an author starts; the explicit setting is what stops that. Six `\noindent` calls remain because they force *horizontal mode* rather than suppress an indent — deleting the one before `\rlap` in the signature block demonstrably moves `example-sig`'s output. No rendered output changes. `examples/example-multipara.tex` is added as the regression witness: a continuation paragraph inside a body item is the only paragraph in a memo the class does not start itself, so it is the only place a stray `\parindent` could reach the page.

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
