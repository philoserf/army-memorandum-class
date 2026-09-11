# References

Source material for the regulation this class implements. **This file is the only tracked
thing in this directory** — everything beside it is ignored by `.gitignore` (`references/*`
plus a negation for this file).

That split is deliberate. The documents below are downloaded references, not sources and
not build inputs; each is reissued on its own schedule by an authority that is not this
repository. Committing a binary here would pin a snapshot that goes stale silently and
bloat the tree to no purpose. A tracked list of **stable record-page URLs** — pages that
survive reissue, as distinct from direct PDF links whose filenames encode a revision
number — keeps the pointer fresh and the tree small.

So: fetch what you need into this directory, and add a row here rather than a new
`.gitignore` pattern.

## What is here now

| Path                        | What it is                                              |
| --------------------------- | ------------------------------------------------------- |
| `Army Regulation 25–50.pdf` | The regulation, 10 Oct 2020 / 4 Oct 2024 revision       |
| `figures/`                  | 59 specimen figures named by caption, plus the title-page seal |

### Check currency before trusting the local copy

The local PDF carries the base publication date **10 October 2020** and the
**administrative revision dated 4 October 2024**; its PDF metadata records a creation date
of May 2025 and carries no edition string, so the revision date above is the only version
marker it has. AR 25–50 has taken seven administrative revisions since 2020 — roughly one a
year — so a copy on disk is _probably_ current, never _definitely_ current.

Check the record page before treating it as the spec:

<https://armypubs.army.mil/ProductMaps/PubForm/Details.aspx?PUB_ID=1020633>

The Summary of Change at the front of any newer issue lists what moved, which is far
faster than diffing the documents.

## The figures are screenshots — read this before measuring anything

Every specimen figure in AR 25–50 is a **96 dpi raster image**, not text. `pdftotext`
recovers the captions and nothing else. This is the single most important limitation of
the regulation as a working reference for a document class, because the prose specifies
placement in _lines_ — "the second line below the seal," "the third line below the office
symbol," "the fifth line below the authority line" — and never states letterhead geometry,
seal dimensions, or tab-stop distances in absolute units. Those exist only in the pictures.

What that means in practice:

- **Good for**: relative structure. Indent depths, line counts between blocks, which
  elements sit on a shared line, ragged-right behavior, where the enclosure list falls
  relative to the signature block. At 96 dpi one pixel is about 0.0104 in (0.75 pt), so
  a ¼-inch indent is ~24 px and reads off cleanly.
- **Better than that, in a way the prose never is**: several figures — 2‑1 above all —
  carry a **column of blank-line counts down the left gutter**, numbering the lines between
  every pair of elements. That is the vertical spacing specification, stated exactly, and
  it is the single best reason to look at the pictures at all. Figure 2‑1 also states the
  subparagraph indents outright (¼ inch at the first subdivision, ½ inch at the second) and
  caps subdivision depth at three, none of which appears in the body text of chapter 2.
- **Useless for**: font metrics, kerning, exact point sizes, hairline rules. Do not try to
  settle a typographic question against a JPEG-generation screenshot of a Word document.

For anything the figures cannot answer, you need the **APD letterhead template** — see the
acquisition list below.

### Re-extracting the figures

`tools/extract-ar-figures.py` does this. It needs Poppler (`pdfimages`, `pdftotext`), which
TeX Live 2026 ships but which is not on a non-interactive shell's `PATH`:

```sh
export PATH="$HOME/texlive/2026/bin/universal-darwin:$PATH"
python3 tools/extract-ar-figures.py
```

It names each figure from the caption printed on its own page rather than from a hardcoded
page map, so a reissue that repaginates the regulation still yields correct names — the
page number in the filename shifts, the caption does not. Pages carrying more than one
figure pair the Nth image with the Nth caption; that ordering was verified against
Figure D‑14 on a three-figure page after the last run. The title-page seal is the only
image with no `Figure N.` caption, so it lands as `p004-uncaptioned-0.png` and was renamed
by hand.

Page ranges in the current issue (PDF page numbers, which run **8 ahead** of the printed
page numbers in the footer):

| PDF pages | Content                                                         |
| --------- | --------------------------------------------------------------- |
| 4         | DoD seal on the title-page masthead, 220 dpi — the one non-96    |
| 20–45     | Figures 2‑1 … 2‑19, memorandums — **the ones that matter here**  |
| 48–53     | Figures 3‑1 … 3‑5, letters — not implemented by this class       |
| 56        | Figure 4‑1, tabbing correspondence                               |
| 70–71     | Figures B‑1, B‑2, protocol sequence                              |
| 90–101    | Figures D‑1 … D‑24, authority lines and signature blocks         |

## Worth acquiring, in order of value to this class

Ranked by what the class actually needs settled, **not** by the regulation's own
Required/Related split — most of Appendix A Section I is records-management policy with no
bearing on typesetting.

1. **APD computer-generated letterhead template** — cited at AR 1‑16b(1)–(3). The highest
   value item by a wide margin: the class hardcodes the DOD letterhead block, and this
   template is the only primary source for seal size and position and for letterhead font
   sizing. It is precisely the number the AR prose withholds and the screenshots cannot
   give. <https://armypubs.army.mil/tools/pubsresources.aspx>
2. **DoDM 5110.04 Volume 2, _DoD Manual for Written Material: Examples and Reference
   Material_** — and Volume 1, _Correspondence Management_. AR 1‑16b(4) and 1‑19c defer to
   these for letterhead and font guidance for HQDA principals. Volume 2 is the examples
   manual, which is the gap the rasterized figures leave. <https://www.esd.whs.mil/dd/>
3. **DoDM 5200.01 Volume 2, _DoD Information Security Program: Marking of Information_** —
   the class ships classification marks (`\am@classmark`). AR chapter 8 deleted its own
   marking figures in the 2020 revision expressly to point here, so this is now the only
   specimen source for the banners the class draws. Add **DoDI 5200.48**, _Controlled
   Unclassified Information_, only if CUI banners come into scope. <https://www.esd.whs.mil/dd/>
4. **DAIG Correspondence and Reports Guide** — already cited in the repo README as the
   source of the Times New Roman default, with the consulted edition's URL recorded in
   `CHANGES.md`, but never kept locally. It drives a default that the README's own font
   section contradicts, so it belongs at hand.
   <https://ig.army.mil/IG-SCHOOL-RESOURCES/Resources-for-Correspondence-and-Reports/>
5. **The superseded AR 25–50, dated 17 May 2013** — the class is copyright 2011 and the
   last commit shared with upstream predates the 2020 major revision entirely. Diffing the
   two editions is the cheapest systematic way to find rules the class still encodes from
   the old edition. Reachable from the record page above; the 2020 Summary of Change lists
   what moved.

Lower priority, useful only for specific questions: **U.S. Government Publishing Office
Style Manual** (<https://www.govinfo.gov/collection/gpo-style-manual>) for capitalization
and abbreviation questions the AR defers on, and **DoDI 4000.19**, _Support Agreements_,
if MOU/MOA support is ever added (AR 2‑6c(5)(e)).

## Gated — do not add these as to-dos

Both are cited by AR 25–50 as authoritative and both appear to sit behind DoD
authentication — not verified from here, so try them before believing this paragraph.
If they do need a CAC on a government network, treat their content as unavailable
rather than as a pending to-do:

- **HQDA Writing and Product SOP** — `csa.army.pentagon.mil`. Cited throughout the 4 Oct
  2024 revision; it is what the rescinded DA Memo 25–52 was replaced by, and therefore
  where font size and type decisions now formally live.
- **ARIMS / Army Addresses and Office Symbols Online** — `arims.army.mil`. The source of
  the record numbers AR 2‑4a(2) requires after the office symbol.
