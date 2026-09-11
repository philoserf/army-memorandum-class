# Changelog

---

## [Unreleased]

### Changed

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
