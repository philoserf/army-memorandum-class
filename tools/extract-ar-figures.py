#!/usr/bin/env python3
"""Extract the specimen figures from a local copy of AR 25-50 as PNGs.

Every figure in AR 25-50 is a 96 dpi raster screenshot rather than text, so
`pdftotext` recovers the captions and nothing else. Those pictures are the only
place the regulation states its vertical spacing (figure 2-1 numbers the blank
lines between elements down its left gutter) and its subparagraph indents, which
makes them worth having on disk beside the class.

Figures are named from the caption printed on their own page rather than from a
hardcoded page map, so a reissue that repaginates the document still produces
correct names -- the page number in the filename shifts, the caption does not.

Pages carrying more than one figure (appendix D packs up to three) pair the Nth
image with the Nth caption. That holds because pdfimages emits in content-stream
order, which for this document is top-to-bottom; it is verified by spot-checking
a multi-figure page against its captions after a run.

Output goes to references/figures/, which .gitignore excludes -- see
references/README.md for why none of it is tracked, and for what the figures can
and cannot settle.

Requires Poppler for pdfimages and pdftotext. That is Homebrew's `poppler`, not
TeX Live -- TeX Live ships neither binary, despite being the source of everything
else in this repository's build. See the repo Brewfile.

Usage:
    python3 tools/extract-ar-figures.py [path/to/AR.pdf]
"""

import re
import shutil
import subprocess
import sys
from functools import cache
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
# En dash, not a hyphen: that is how the regulation spells its own number, and
# how the downloaded file is named. See allowed-confusables in ruff.toml.
DEFAULT_PDF = REPO / "references" / "Army Regulation 25–50.pdf"
OUTDIR = REPO / "references" / "figures"

# "Figure 2-1. Using and preparing a memorandum..." -- note the en dash, which is
# what the regulation actually prints, and the appendix forms (Figure D-14).
CAPTION = re.compile(r"^\s*(Figure\s+[0-9A-Z]+–[0-9]+\.\s*.+?)\s*$")


@cache
def tool(name: str) -> str:
    """Resolve a Poppler executable to an absolute path.

    Resolved rather than invoked by bare name so that a missing Poppler is one
    clear message instead of a FileNotFoundError from inside subprocess -- and
    so the paths handed to subprocess are absolute, which is what ruff's S607
    asks for. TeX Live ships these but is not on a non-interactive shell's PATH;
    see the module docstring for the export.
    """
    resolved = shutil.which(name)
    if resolved is None:
        sys.exit(
            f"{name} not found on PATH. It ships with Poppler, and with TeX Live:\n"
            '  export PATH="$HOME/texlive/2026/bin/universal-darwin:$PATH"',
        )
    return resolved


def slug(text: str) -> str:
    """Reduce a figure caption to a filename-safe lowercase slug."""
    text = text.replace("–", "-").replace("—", "-")
    text = re.sub(r"[^A-Za-z0-9]+", "-", text).strip("-").lower()
    return re.sub(r"-+", "-", text)[:90]


def pages_with_images(pdf: Path) -> dict[int, int]:
    """Map PDF page number -> count of images on it."""
    out = subprocess.run(
        [tool("pdfimages"), "-list", str(pdf)],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.splitlines()[2:]  # drop the two header rows

    counts: dict[int, int] = {}
    for line in out:
        fields = line.split()
        if fields:
            page = int(fields[0])
            counts[page] = counts.get(page, 0) + 1
    return counts


def captions_on(pdf: Path, page: int) -> list[str]:
    """Return the figure captions printed on one page, in top-to-bottom order."""
    text = subprocess.run(
        [tool("pdftotext"), "-layout", "-f", str(page), "-l", str(page), str(pdf), "-"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return [m.group(1) for line in text.splitlines() if (m := CAPTION.match(line))]


def main() -> None:
    """Extract every figure in the PDF to OUTDIR, named by caption."""
    pdf = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PDF
    if not pdf.exists():
        sys.exit(
            f"no such file: {pdf}\n"
            "Download AR 25-50 into references/ first; see references/README.md.",
        )

    OUTDIR.mkdir(parents=True, exist_ok=True)
    tmp = OUTDIR / ".tmp"
    uncaptioned = 0

    for page in sorted(pages_with_images(pdf)):
        caps = captions_on(pdf, page)

        tmp.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                tool("pdfimages"),
                "-png",
                "-f",
                str(page),
                "-l",
                str(page),
                str(pdf),
                str(tmp / "img"),
            ],
            check=True,
        )

        for i, img in enumerate(sorted(tmp.iterdir())):
            if i < len(caps):
                name = f"p{page:03d}-{slug(caps[i])}.png"
            else:
                # Page 4's masthead seal is the only such image in the 2024
                # issue: a real illustration with no "Figure N." caption.
                name = f"p{page:03d}-uncaptioned-{i}.png"
                uncaptioned += 1
            shutil.move(img, OUTDIR / name)
            print(name)
        shutil.rmtree(tmp)

    if uncaptioned:
        print(
            f"\n{uncaptioned} image(s) had no caption and need naming by hand.",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
