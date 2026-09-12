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

Roughly 17 MB, none of it tracked.

| File                                             | What it is                                        | Fetched    |
| ------------------------------------------------ | ------------------------------------------------- | ---------- |
| `Army Regulation 25–50.pdf`                      | The regulation, 10 Oct 2020 / 4 Oct 2024 revision | 2026-09-11 |
| `DAIG-2025-Correspondence-and-Reports-Guide.pdf` | DAIG guide, August 2025 edition, 32 pp            | 2026-09-11 |
| `DoDM-5110.04-V2.pdf`                            | Written Material: Examples and Reference Material | 2026-09-11 |
| `DoDM-5200.01-V2.pdf`                            | Information Security: Marking of Information      | 2026-09-11 |
| `DoDI-5200.48.pdf`                               | Controlled Unclassified Information (CUI)         | 2026-09-11 |
| `DoDI-4000.19.pdf`                               | Support Agreements (MOU/MOA content)              | 2026-09-11 |
| `figures/`                                       | 59 specimen figures + the AR title-page seal      | —          |
| `letterhead/`                                    | APD `DALetterhead.dotm` + `DAMemoPad.dotm`        | 2026-09-11 |

### Currency: verified, not assumed

On **2026-09-11** the local `Army Regulation 25–50.pdf` was compared against the PDF then
being served from the record page. The two are **byte-identical** (MD5
`82c0bdb41e22f19d8923032da089dc2a`), so the local copy is the current issue — base
publication 10 October 2020, administrative revision 4 October 2024.

That will not stay true. AR 25–50 has taken seven administrative revisions since 2020,
roughly one a year. Re-run the comparison rather than trusting this paragraph:

```sh
curl -sSL -o /tmp/ar.pdf \
  https://armypubs.army.mil/epubs/DR_pubs/DR_a/ARN42124-AR_25-50-007-WEB-13.pdf
md5 -q /tmp/ar.pdf "references/Army Regulation 25–50.pdf"
```

The record page, which survives reissue when that direct link does not:
<https://armypubs.army.mil/ProductMaps/PubForm/Details.aspx?PUB_ID=1020633>

### Fetching: plain curl will not work

`ig.army.mil` and `www.esd.whs.mil` sit behind an Akamai edge WAF that answers `403` to
curl regardless of user-agent, referer, cookie jar, or a full `Sec-Fetch-*` header set.
`armypubs.army.mil` is the exception and serves the AR to curl directly.

What worked for the rest was driving a real browser (Safari via `safaridriver --mcp`),
opening a page on the target origin and issuing a same-origin `fetch()` from the page
context, then handing the blob to a synthetic `<a download>`. Anything that needs to be
re-fetched from those two hosts will need the same treatment.

Note also that the DoD issuances site now brands itself "DoW Issuances", and its file
naming is not uniform — `DoDM-5200.01-V2` is `520001m_vol2.pdf` (with the issuance-type
letter) while `DoDM-5110.04-V2` is `511004vol2.pdf` (without). Probe rather than guess.

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
  relative to the signature block. At 96 dpi one pixel is about 0.0104 in (0.75 pt), so a
  ¼-inch indent is ~24 px and reads off cleanly.
- **Better than that, in a way the prose never is**: several figures — 2‑1 above all —
  carry a **column of blank-line counts down the left gutter**, numbering the lines between
  every pair of elements. That is the vertical spacing specification, stated exactly, and
  it is the single best reason to look at the pictures at all. Figure 2‑1 also states the
  subparagraph indents outright (¼ inch at the first subdivision, ½ inch at the second) and
  caps subdivision depth at three, none of which appears in the body text of chapter 2.
- **Useless for**: font metrics, kerning, exact point sizes, hairline rules. Do not try to
  settle a typographic question against a JPEG-generation screenshot of a Word document.

`DoDM-5110.04-V2.pdf` is the partial remedy: it is DoD's own examples-and-reference manual,
and AR 1‑16b(4) and 1‑19c defer to it. It does not carry Army letterhead geometry, so it
does not close the gap the APD template would — see below.

### Re-extracting the figures

`tools/extract-ar-figures.py` does this. It needs Poppler for `pdfimages` and `pdftotext`
— Homebrew's `poppler`, which the repo `Brewfile` records. TeX Live ships neither binary,
so no `PATH` export is needed here; that export is for `lualatex` and friends.

```sh
python3 tools/extract-ar-figures.py
```

It names each figure from the caption printed on its own page rather than from a hardcoded
page map, so a reissue that repaginates the regulation still yields correct names — the
page number in the filename shifts, the caption does not. Pages carrying more than one
figure pair the Nth image with the Nth caption; that ordering was verified against Figure
D‑14 on a three-figure page. The title-page seal is the only image with no `Figure N.`
caption, so it lands as `p004-uncaptioned-0.png` and was renamed by hand.

Page ranges in the current issue (PDF page numbers, which run **8 ahead** of the printed
page numbers in the footer):

| PDF pages | Content                                                         |
| --------- | --------------------------------------------------------------- |
| 4         | DoD seal on the title-page masthead, 220 dpi — the one non-96   |
| 20–45     | Figures 2‑1 … 2‑19, memorandums — **the ones that matter here** |
| 48–53     | Figures 3‑1 … 3‑5, letters — not implemented by this class      |
| 56        | Figure 4‑1, tabbing correspondence                              |
| 70–71     | Figures B‑1, B‑2, protocol sequence                             |
| 90–101    | Figures D‑1 … D‑24, authority lines and signature blocks        |

## The letterhead template — recovered, and what it settles

`AR 25-50` 1-16b delegates letterhead to "the letterhead template provided on APD's
website". That page is now behind Army SSO, but the **Internet Archive holds captures from
before it was gated**. The 2022-09-29 capture lists the template files, and two still
resolve:

```sh
TS=20220929205504
curl -sSL -o DALetterhead.dotm \
  "https://web.archive.org/web/$TS/https://armypubs.army.mil/Tools/Letterhead/DALetterhead.dotm"
curl -sSL -o DAMemoPad.dotm \
  "https://web.archive.org/web/$TS/https://armypubs.army.mil/Tools/Letterhead/DAMemoPad.dotm"
```

(`LetterheadInstructions.docx` and `LetterheadKW60.dotm` are listed on that page but 404 in
the archive. A 2016 capture exists too, but predates the template entirely.)

A `.dotm` is OOXML — a zip of XML — so the geometry reads out directly rather than having
to be measured off a screenshot. **This is the primary source the repository had never
been able to consult**, and it confirms the numbers the class had been carrying on its own
authority:

| Quantity            | `DALetterhead.dotm`                              | `armymemo.cls`                  |
| ------------------- | ------------------------------------------------ | ------------------------------- |
| Seal size           | `wp:extent` 914400 × 914400 EMU = 1.000×1.000 in | `\includegraphics[width=1in]`   |
| Seal anchor         | `relativeFrom="page"`, both axes                 | `at (current page.north west)`  |
| Seal offset         | `posOffset` 457200 EMU = 0.500 in, H and V       | `xshift=0.5in, yshift=-0.5in`   |
| Left/right/bottom   | 1440 twips = 1.000 in                            | `margin=1in`                    |
| Department line     | 10 pt                                            | `\fontsize{10pt}{10pt}`         |
| Letterhead typeface | document default Arial; `CompanyName` Arial Bold | `\fontfamily\sfdefault` (Arial) |
| The mark itself     | `media/image1.jpeg` — the **DoD** seal           | `DODb1.pdf` default             |

Every one matches. Two caveats worth keeping honest:

- The template's **address lines inherit** their size (style `CompanyName`, itself
  inheriting), so they do not resolve to a single number. The class's 8 pt for those lines
  remains its own choice, not something the template confirms.
- The template's **top margin is 1.5 in**; the class reaches an equivalent text start
  through `margin=1in` plus `includehead` and a computed `headheight`, so those are not
  directly comparable figures.

`DAMemoPad.dotm` is a different product — a 5.5 × 8.5 in memo pad with a 0.75 in seal — not
the letter-size memorandum this class sets. Keep it for reference, do not take numbers from
it.

The template also carries legacy art it no longer uses: a Korean War 50th Anniversary
commemorative seal (`media/image4.png`), which dates the file to the early 2000s. The
header references only `image1.jpeg`, the DoD seal.

## Still wanted, and why each is hard

1. ~~APD computer-generated letterhead template~~ — **obtained**, see below. The live page
   is SSO-gated, but the Internet Archive has it.
2. **DoDM 5110.04 Volume 1**, _Correspondence Management_ — Volume 2 was retrieved and
   cites "Volume 1 of this manual" repeatedly, so it exists, but it is not published at the
   path its sibling occupies (`511004vol1.pdf` is a 404, as is a `cancelled/` variant).
   Either renamed or not publicly posted; check the DoW Issuances site directly.
3. **The superseded AR 25–50, dated 17 May 2013** — APD does not retain it. The record page
   lists only the current `WEB-13` PDF, and the obvious legacy paths return soft 404s (a
   1226-byte HTML page served as `200`). Diffing the 2013 and 2020 editions would be the
   cheapest way to find rules the class still encodes from before the 2020 rewrite; that
   will need a copy from somewhere other than APD.

Lower priority: the **U.S. Government Publishing Office Style Manual**
(<https://www.govinfo.gov/collection/gpo-style-manual>) for capitalization and abbreviation
questions the AR defers on.

## Gated — do not add these as to-dos

Cited by AR 25–50 as authoritative, and behind DoD authentication. Treat their content as
unavailable rather than pending:

- **HQDA Writing and Product SOP** — `csa.army.pentagon.mil`. Cited throughout the 4 Oct
  2024 revision; it is what the rescinded DA Memo 25–52 was replaced by, and therefore
  where font size and type decisions now formally live.
- **ARIMS / Army Addresses and Office Symbols Online** — `arims.army.mil`. The source of
  the record numbers AR 2‑4a(2) requires after the office symbol.
- **The APD letterhead template** — the _live_ page at
  `armypubs.army.mil/tools/pubsresources.aspx` is SSO-gated (it `302`s to
  `federation.eams.army.mil/sso/authenticate`), confirmed 2026-09-11. The template itself
  was recovered from the Internet Archive anyway; see "The letterhead template" above.
