#!/usr/bin/env python3
"""Assert the AR 25-50 vertical placements that the golden files cannot see.

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

Whether a document has an authority line is read from its .tex source rather
than guessed from the PDF: "the last uppercase line ending in a colon" also
matches SUBJECT: and would silently measure the wrong gap.

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

# The signature column starts at 0.5\textwidth past a 1in margin: 72 + 234 = 306.
# The page number is centred on the same axis, so digit-only lines are dropped
# before this window is applied.
SIG_COLUMN_MIN_PT = 300.0
SIG_COLUMN_MAX_PT = 312.0

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


def find_signature(lines: list[Line]) -> Line | None:
    """Return the first line of the signature column, or None.

    Digit-only lines are dropped first. The page number is centred on the same
    axis as the signature column and would otherwise match.
    """
    candidates = [
        ln
        for ln in lines
        if SIG_COLUMN_MIN_PT < ln.xmin < SIG_COLUMN_MAX_PT
        and not ln.text.strip().isdigit()
    ]
    return min(candidates, key=lambda ln: (ln.page, ln.ymin)) if candidates else None


def last_line_above(lines: list[Line], marker: Line) -> Line | None:
    """Return the lowest left-column line above `marker` on the same page."""
    above = [
        ln
        for ln in lines
        if ln.page == marker.page
        and ln.ymin < marker.ymin
        and ln.xmin < SIG_COLUMN_MIN_PT
    ]
    return max(above, key=lambda ln: ln.ymin) if above else None


def find_authority(lines: list[Line], signature: Line) -> Line | None:
    """Return the authority line: the lowest left-column line above the block."""
    return last_line_above(lines, signature)


def check_example(pdf: Path, tex: Path) -> list[Result]:
    """Assert AR 2-4c(1) and 2-4c(2)(a) against one built example."""
    name = pdf.stem
    lines = [
        ln
        for ln in extract_lines(pdf)
        if not ln.text.strip().isdigit() and "UNCLASSIFIED" not in ln.text
    ]
    signature = find_signature(lines)
    if signature is None:
        return [Result(name, "signature block", "skip", "no signature column found")]

    if has_authority_line(tex):
        authority = find_authority(lines, signature)
        if authority is None or authority.ymin < HEAD_REGION_PT:
            return [
                Result(name, "signature block", "skip", "authority line not locatable")
            ]
        results = [
            measure(
                name,
                "AR 2-4c(2)(a) authority -> signature",
                authority,
                signature,
                5.0,
            )
        ]
        body = last_line_above(lines, authority)
        if body is not None and body.ymin >= HEAD_REGION_PT:
            results.append(
                measure(name, "AR 2-4c(1) text -> authority", body, authority, 2.0)
            )
        return results

    body = last_line_above(lines, signature)
    if body is None or body.ymin < HEAD_REGION_PT:
        return [
            Result(name, "signature block", "skip", "no body text above the signature")
        ]
    return [measure(name, "AR 2-4c(2)(a) text -> signature", body, signature, 5.0)]


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
