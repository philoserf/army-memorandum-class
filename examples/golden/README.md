# Golden files

The tracked rendered reference for `armymemo.cls`. For a document class, rendered
output _is_ the behavior — these files are the assertions the examples had none of
before (issue #51).

Each example has two:

| File           | Contents                                            |
| -------------- | --------------------------------------------------- |
| `<name>.txt`   | `pdftotext -layout` output of `examples/<name>.pdf` |
| `<name>.pages` | the page count from `pdfinfo`, one integer          |

## Never hand-edit these files

Regenerate with `make golden`, which refuses to write unless two independent builds
extract byte-for-byte identically.

The `.txt` files contain **one form feed per page**. An editor that strips or
normalizes them silently breaks page-break detection, and page breaks are where this
class's most serious bug lives (#1). Hand-editing is the single most likely way to
corrupt this harness without anyone noticing.

## Two goldens were deliberately captured buggy — and both have since paid off

The baselines for the one-address (#26) and zero-enclosure (#29) cases were captured
showing the defects **as they rendered at the time**, not the intended output. A
baseline that already contains the corrected rendering cannot demonstrate that a later
fix changed anything.

Both fixes have now landed and the diffs are the proof:

- **#26**, milestone 3 — `example-oneaddress.txt` lost the three boilerplate lines that
  had been appended to the single real address.
- **#29**, milestone 4 — `example-noencl.txt` had `DISTRIBUTION:` printed on the *same
  line* as the signer's name; it now sits below the closing block.

The technique is the point, not those two files: when a milestone is expected to change
output, capture the broken baseline first so the fix has something to diff against.

## Provenance

Captured with:

- `pdftotext version 26.09.0` (poppler)
- LuaHBTeX 1.24.0, TeX Live 2026
- Times New Roman and Arial resolving from `/System/Library/Fonts/Supplemental/`

The fonts matter. TeX Gyre Termes and Heros — the fallbacks added by #14 — are
_metric-compatible_ with Times and Helvetica, so a golden captured on a machine
missing the real fonts could pass a text diff while recording the wrong typeface. The
harness greps each build log for the fallback warning and refuses to capture when it
fires.

A poppler or TeX Live major upgrade can shift `-layout` column reconstruction. The
signature of that is **every golden diffing at once, with column-only changes** — which
is how you tell it from a real regression. The response is `make golden` plus a bump to
the versions above, not a code fix.
