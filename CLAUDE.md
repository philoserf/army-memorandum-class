# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A LaTeX document class (`armymemo.cls`) implementing the U.S. Army memorandum format
per AR 25-50. There is no application code — the deliverables are the class file, the
bundled `digsig.sty`, and the `examples/` that exercise them.

Fork: `origin` = `x3c3/army-memorandum-class`, `upstream` = `glallen01/army-memorandum-class`.
Upstream changes land as merged PRs. Check `git log --oneline upstream/master..HEAD` for
local divergence before syncing.

## Toolchain

- **LuaLaTeX or XeLaTeX is required** — the class uses `fontspec` and calls
  `\setmainfont` / `\setsansfont` directly. pdflatex will not compile it.
- **Times New Roman and Arial must be installed system-wide** or compilation fails.
- `chktex` is the only linter; `latexmk` drives builds; `latexrun` is optional.

None of these are installed on this machine by default — check before promising a build.

## Commands

```sh
make                # build every examples/*.pdf (delegates to examples/Makefile)
make check          # chktex armymemo.cls  -- the only lint/test in the repo
make clean          # remove built PDFs and aux files
make proper         # clean + remove *.out

cd examples && latexmk -lualatex example.tex     # build a single example
```

The README shows `latexmk -pdf -pvc -lualatex example.tex`; `-pvc` is continuous-preview
watch mode — drop it for one-shot builds.

`examples/Makefile` prefers `../latexrun` if that executable exists, else falls back to
`latexmk -lualatex`.

## Gotchas

- **Editing `armymemo.cls` does not trigger a rebuild.** The pattern rule is
  `%.pdf: %.tex` — the class is only a prerequisite of the phony `all`, not of the PDFs.
  After a class change run `make clean && make`, or invoke `latexmk` directly.
- **`examples/*.pdf` are tracked.** Rebuilding dirties the working tree, and `make clean`
  deletes tracked files rather than just build output. Upstream commits the regenerated
  PDFs in the same commit as the class change (e.g. 9e6d5ef, 48e3c3b), so include them
  when changing rendered output.
- **The README is stale on fonts.** It says the default is Arial; the class sets
  `\setmainfont{Times New Roman}` (armymemo.cls:92), per the 4 OCT 24 AR 25-50 update and
  DAIG guidance documented in `CHANGES.md`. Users override with `\setmainfont{Arial}`.
- **Version lives in two places** — the `\ProvidesClass{armymemo}[YYYY/MM/DD X.Y.Z ...]`
  line and `CHANGES.md`. Bump both.
- `examples/armymemo.cls`, `examples/digsig.sty`, and `examples/DODb1.pdf` are symlinks to
  the repo root, so the examples always compile against the live class.

## Architecture

The class loads KOMA-Script `scrartcl` and does nearly all its work in two hooks:

- `\AtBeginDocument` — classification banner (`background` package), logo, and the
  DOD letterhead block.
- `\AtEndDocument` — authority line, signature block (drawn as a `tikzpicture` overlay
  positioned at `0.5\textwidth`), then enclosures, distribution, and copies-furnished.

The document body itself is just a relabeled `enumerate`: `enumitem` re-declares it to
depth 9 with AR-style labels `1.` / `a.` / `(1)` / `(a)`. Authors write nested lists,
not sections.

**Metadata pattern.** Every user-facing field follows one of two shapes:

- _Scalar_: `\officesymbol{...}` → `\def\am@officesymbol{...}`, with a default set by
  invoking the setter immediately after definition. Required fields default to
  `\am@MissingRequiredArgError` / `...Warning`, which emit a build error or warning _and_
  substitute a visible placeholder (`OFFICE SYMBOL`, `DRAFT`) into the output.
- _List_: `\address`, `\addencl`, `\adddistro`, `\addcf`, `\addmemoline` /
  `\multimemofor` / `\multimemothru` use etoolbox `\listadd` into `\am@list@*` plus a
  counter, rendered by an `\am@*` loop inside the appropriate hook.

Adding a new field means: define the setter, store into an `am@`-prefixed internal, and
render it from the correct hook. Counters exist so the renderers can vary output between
zero, one, and many entries (e.g. `Encl` vs `2 Encls`; `\enclsnocount` suppresses the
count per AR 25-50 Figure 4-4).

**Options.** `digsig` is the only class-specific option — it sets an etoolbox bool and
loads the bundled `digsig.sty`, which adds an interactive PDF signature field to the
signature block. Everything else is passed through to `scrartcl` via `\DeclareOption*`.

`am@`-prefixed macros are internal — a document can't reach them without `\makeatletter`.
Everything else is public API.
