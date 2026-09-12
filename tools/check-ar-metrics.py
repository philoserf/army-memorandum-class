#!/usr/bin/env python3
r"""Assert the AR 25-50 vertical placements that the golden files cannot see.

The golden harness compares `pdftotext -layout` text. That captures line
*structure* -- which lines exist, and how many blank lines separate them -- and
it is the right check for most of what this class does. It is blind to sub-line
vertical position, because the extractor quantises vertical space into text rows:
a block can move by a fifth of an inch and still land in the same row.

That blind spot is not hypothetical. Issue #99 was the signature block sitting
6.57 baselines below the last line of text where AR 25-50 2-4c(2)(a) requires
five. The fix moved it 22.73pt up the page, and the extracted text before and
after the fix is byte-identical, so `task test` could neither catch the bug nor
lock in the repair. This script closes that gap, the way the `.diag` capture in
tools/run-tests.sh closed the one around class diagnostics.

What it measures, per example, from `pdftotext -bbox-layout`:

    AR 2-4c(1)     authority line     2 lines below the last line of text
    AR 2-4c(2)(a)  signature block    5 lines below the authority line, or
                                      5 lines below the last line of text when
                                      there is no authority line
    AR 2-4c(2)(a)  signature block    in the centre of the page
    AR 2-5d        page number        centred, ~1 inch from the bottom edge

Whether a document has an authority line is read from its .tex source rather
than guessed from the PDF: "the last uppercase line ending in a colon" also
matches SUBJECT: and would silently measure the wrong gap. The signature block is
located the same way, by uppercasing the document's own \author -- an earlier
version looked for it in a window around the centre column, which meant the one
bug that moved it OUT of that window (#117, the signature at the left margin with
no enclosures) registered as "cannot locate, skipped" rather than as a failure. A
check that goes quiet exactly when the thing it measures is broken is worse than
no check.

An example whose parts cannot be identified with confidence is reported as
skipped, never as passing. Skips are expected -- a memo whose closing is pushed
onto a page of its own has no body text above the signature to measure from.

Read TOLERANCE_BL before trusting a passing run: this resolves errors of roughly
half a line and upward, which is the size of the bugs the goldens cannot see. It
is not a precision instrument, because pdftotext reports bounding boxes rather
than baselines and boxes move with the glyphs inside them.

Requires Poppler for pdftotext. That is Homebrew's `poppler`, not TeX Live.

Usage:
    python3 tools/check-ar-metrics.py [path/to/examples]
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

# Measured from consecutive within-paragraph lines in any built example. The
# class sets 12pt type; KOMA's resulting leading is this, not 12pt.
BASELINESKIP_PT = 14.45

# Wide on purpose, and the width is a measurement limit rather than slack.
#
# pdftotext reports each line's bounding box, not its baseline, and a box is
# glyph-sensitive at both ends: yMin rises with ascenders and capitals, yMax
# falls with descenders. Measuring one gap three ways shows the spread --
# "5. POC for this memo is John Doe..." to "AUTHORITY LINE:" reads 2.27 bl by
# yMin and 1.92 bl by yMax, for a gap that is 2.00 by construction. Comparisons
# between lines of similar glyph profile are exact (every all-caps to all-caps
# pair here measures a whole number), but the mixed case cannot be resolved
# better than about a third of a line from this data.
#
# So this is a line-level guard, not a precision instrument. It catches the
# class of error the goldens miss -- a block landing on the wrong line, which is
# what #99 was at 1.57 baselines out -- and it will not notice a one-point
# drift. Tightening it without a real baseline source would make it flap.
TOLERANCE_BL = 0.35

# AR 2-4c(2)(a) puts the signature block in the centre of the page. The class
# fixes letterpaper and a 1in margin -- both AR requirements, both deliberately
# not overridable -- so the column is 0.5\textwidth past the margin: 72 + 234.
SIG_COLUMN_PT = 306.0

# Half a point. This is a horizontal box position, not a glyph-sensitive vertical
# measurement, so it does not need the latitude TOLERANCE_BL does.
SIG_COLUMN_TOLERANCE_PT = 0.5

# Used only to separate left-column material from the signature column when
# scanning for body text, never to decide where the signature is.
LEFT_COLUMN_MAX_PT = 300.0

# AR 2-5d: "Center the page number approximately 1-inch from the bottom of the
# page." Centred is exact; the distance is not, and the regulation says so.
PAGE_NUMBER_FROM_BOTTOM_PT = 72.0
PAGE_NUMBER_CENTRE_PT = 306.0

# A tenth of an inch, which is what "approximately" is being read as. The class
# lands at 0.964in; the value before #109 was 0.763in, a quarter inch short, and
# this is set to catch that without pretending the AR states an exact figure.
PAGE_NUMBER_TOLERANCE_PT = 7.2

# Lines starting above this are letterhead or the continuation-page head, never
# body text. Used only to decide that a page carries no measurable body.
HEAD_REGION_PT = 100.0

XHTML = "{http://www.w3.org/1999/xhtml}"


@dataclass(frozen=True)
class Line:
    """One extracted text line, positioned in PDF points from the top-left."""

    page: int
    ymin: float
    xmin: float
    text: str


@dataclass(frozen=True)
class Result:
    """The outcome of one assertion against one example."""

    example: str
    rule: str
    status: str
    detail: str


def extract_lines(pdf: Path) -> list[Line]:
    """Return every non-empty text line in the PDF, with its bounding box."""
    pdftotext = shutil.which("pdftotext")
    if pdftotext is None:
        msg = "pdftotext not found; install Poppler (see the repo Brewfile)"
        raise RuntimeError(msg)
    xml = subprocess.run(
        [pdftotext, "-bbox-layout", str(pdf), "-"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    lines: list[Line] = []
    for page_no, page in enumerate(ET.fromstring(xml).iter(XHTML + "page"), 1):  # noqa: S314
        for node in page.iter(XHTML + "line"):
            text = " ".join("".join(word.itertext()).strip() for word in node).strip()
            if text:
                lines.append(
                    Line(
                        page_no,
                        float(node.get("yMin")),
                        float(node.get("xMin")),
                        text,
                    )
                )
    return lines


def has_authority_line(tex: Path) -> bool:
    r"""Report whether the source sets a non-empty \authority.

    Comments are stripped first: a commented-out setter is not a setter, and
    several examples carry long explanatory headers.
    """
    source = re.sub(r"(?<!\\)%.*", "", tex.read_text(encoding="utf-8"))
    return bool(re.search(r"\\authority\{\s*[^}\s][^}]*\}", source))


def find_author(tex: Path) -> str | None:
    r"""Return the document's \author as the class renders it, in uppercase."""
    source = re.sub(r"(?<!\\)%.*", "", tex.read_text(encoding="utf-8"))
    match = re.search(r"\\author\{([^}]*)\}", source)
    return match.group(1).strip().upper() if match else None


def find_signature(lines: list[Line], author: str | None) -> Line | None:
    """Return the signature block's first line, located by the author's name.

    Found by content rather than by position on purpose: see the module
    docstring. Locating it by column would hide exactly the bugs that move it.
    """
    if author is None:
        return None
    matches = [ln for ln in lines if ln.text.strip() == author]
    return min(matches, key=lambda ln: (ln.page, ln.ymin)) if matches else None


def last_line_above(lines: list[Line], marker: Line) -> Line | None:
    """Return the lowest left-column line above `marker` on the same page."""
    above = [
        ln
        for ln in lines
        if ln.page == marker.page
        and ln.ymin < marker.ymin
        and ln.xmin < LEFT_COLUMN_MAX_PT
    ]
    return max(above, key=lambda ln: ln.ymin) if above else None


def find_authority(lines: list[Line], signature: Line) -> Line | None:
    """Return the authority line: the lowest left-column line above the block."""
    return last_line_above(lines, signature)


def check_page_numbers(pdf: Path, name: str) -> list[Result]:
    """Assert AR 2-5d for every page number in the document."""
    pdftotext = shutil.which("pdftotext")
    if pdftotext is None:
        msg = "pdftotext not found; install Poppler (see the repo Brewfile)"
        raise RuntimeError(msg)
    xml = subprocess.run(
        [pdftotext, "-bbox-layout", str(pdf), "-"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    results: list[Result] = []
    for page_no, page in enumerate(ET.fromstring(xml).iter(XHTML + "page"), 1):  # noqa: S314
        height = float(page.get("height"))
        # The folio is the LOWEST line on the page whose text is exactly this
        # page's number. Both halves matter: example-grid prints a measurement
        # grid full of loose digits, so "the first digit-only line" finds grid
        # labels near the top of the page, and "any digit" finds the wrong one
        # even at the bottom. Position is deliberately not used to find it --
        # see the module docstring on why locating by position hides the bugs
        # that move a thing.
        folios = [
            node
            for node in page.iter(XHTML + "line")
            if "".join(node.itertext()).strip() == str(page_no)
        ]
        if not folios:
            continue  # page 1 carries no folio: the class sets \thispagestyle{plain}
        node = max(folios, key=lambda n: float(n.get("yMax")))
        # yMax approximates the baseline for a line of digits, which carry no
        # descenders -- the one case where the box bottom is the baseline.
        from_bottom = height - float(node.get("yMax"))
        centre = (float(node.get("xMin")) + float(node.get("xMax"))) / 2
        off_v = abs(from_bottom - PAGE_NUMBER_FROM_BOTTOM_PT)
        off_h = abs(centre - PAGE_NUMBER_CENTRE_PT)
        status = (
            "ok"
            if off_v <= PAGE_NUMBER_TOLERANCE_PT and off_h <= SIG_COLUMN_TOLERANCE_PT
            else "FAIL"
        )
        results.append(
            Result(
                f"{name} p{page_no}",
                "AR 2-5d page number",
                status,
                f"{from_bottom / 72:.3f}in from bottom, centre x={centre:.2f}",
            )
        )
    return results


def check_example(pdf: Path, tex: Path) -> list[Result]:
    """Assert AR 2-4c(1) and 2-4c(2)(a) against one built example."""
    name = pdf.stem
    lines = [
        ln
        for ln in extract_lines(pdf)
        if not ln.text.strip().isdigit() and "UNCLASSIFIED" not in ln.text
    ]
    author = find_author(tex)
    signature = find_signature(lines, author)
    if signature is None:
        detail = (
            "no \\author in the source"
            if author is None
            else f"{author!r} not in the PDF"
        )
        return [Result(name, "signature block", "skip", detail)]

    results: list[Result] = []
    offset = abs(signature.xmin - SIG_COLUMN_PT)
    centred = "ok" if offset <= SIG_COLUMN_TOLERANCE_PT else "FAIL"
    results.append(
        Result(
            name,
            "AR 2-4c(2)(a) signature block centred",
            centred,
            f"x={signature.xmin:.2f} (want {SIG_COLUMN_PT:.2f})",
        )
    )

    if has_authority_line(tex):
        authority = find_authority(lines, signature)
        if authority is None or authority.ymin < HEAD_REGION_PT:
            results.append(
                Result(name, "signature block", "skip", "authority line not locatable")
            )
            return results
        results.append(
            measure(
                name,
                "AR 2-4c(2)(a) authority -> signature",
                authority,
                signature,
                5.0,
            )
        )
        body = last_line_above(lines, authority)
        if body is not None and body.ymin >= HEAD_REGION_PT:
            results.append(
                measure(name, "AR 2-4c(1) text -> authority", body, authority, 2.0)
            )
        return results

    body = last_line_above(lines, signature)
    if body is None or body.ymin < HEAD_REGION_PT:
        results.append(
            Result(name, "signature block", "skip", "no body text above the signature")
        )
        return results
    results.append(
        measure(name, "AR 2-4c(2)(a) text -> signature", body, signature, 5.0)
    )
    return results


def measure(name: str, rule: str, upper: Line, lower: Line, want_bl: float) -> Result:
    """Compare the gap between two lines against an expected baseline count."""
    got_bl = (lower.ymin - upper.ymin) / BASELINESKIP_PT
    detail = f"{got_bl:.2f} bl (want {want_bl:.2f})"
    if abs(got_bl - want_bl) <= TOLERANCE_BL:
        return Result(name, rule, "ok", detail)
    return Result(name, rule, "FAIL", detail)


def main(argv: list[str]) -> int:
    """Check every built example and report per-assertion results."""
    default = Path(__file__).parent.parent / "examples"
    examples = Path(argv[1]) if len(argv) > 1 else default
    results: list[Result] = []
    for tex in sorted(examples.glob("*.tex")):
        pdf = tex.with_suffix(".pdf")
        if pdf.exists():
            results.extend(check_example(pdf, tex))
            results.extend(check_page_numbers(pdf, tex.stem))

    failures = [r for r in results if r.status == "FAIL"]
    skips = [r for r in results if r.status == "skip"]
    for r in failures:
        print(f"FAIL {r.example}: {r.rule} -- {r.detail}")
    if not results:
        print("FAIL ar-metrics: no built examples found")
        return 1
    if failures:
        print(f"    {len(failures)} placement(s) outside AR 25-50 tolerance.")
        return 1
    checked = len(results) - len(skips)
    print(f"ok   ar-metrics ({checked} placements verified, {len(skips)} skipped)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
