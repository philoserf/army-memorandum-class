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

## Two goldens deliberately record buggy output

Once the coverage examples land (#52), the baselines for the zero-enclosure (#29) and
one-address (#26) cases will show the defects **as they render today** — not the
intended output. That is the point: a baseline that already contains the corrected
rendering cannot demonstrate that a later fix changed anything. When those bugs are
fixed in milestones 3 and 4, `make golden` will show the change, and that diff is the
proof.

Do not "correct" them.

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
