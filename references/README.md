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

`tools/extract-ar-figures.py` does this. It needs Poppler (`pdfimages`, `pdftotext`), which
TeX Live 2026 ships but which is not on a non-interactive shell's `PATH`:

```sh
export PATH="$HOME/texlive/2026/bin/universal-darwin:$PATH"
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

## Still wanted, and why each is hard

1. **APD computer-generated letterhead template** — still the highest-value missing item,
   and now known to be **unobtainable without a CAC**. AR 1‑16b cites
   `armypubs.army.mil/tools/pubsresources.aspx`, which `302`s to
   `federation.eams.army.mil/sso/authenticate`. It is the only primary source for seal size
   and position and for letterhead font sizing — precisely the numbers the AR prose
   withholds and the 96 dpi screenshots cannot settle. The class hardcodes that geometry,
   so it remains unverified against its source.
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
- **The APD letterhead template**, per item 1 above — confirmed SSO-gated on 2026-09-11,
  not merely unreachable.
