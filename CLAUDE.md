# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A LaTeX document class (`armymemo.cls`) implementing the U.S. Army memorandum format
per AR 25-50. There is no application code — the deliverables are the class file, the
bundled `digsig.sty`, and the `examples/` that exercise them.

## Repo identity — read before any `gh` command

- `origin` = `philoserf/army-memorandum-class`. This repo **already graduated** from the
  `x3c3` org to `philoserf`, per the rule in `~/source/x3c3/CLAUDE.md` that a fork
  diverging meaningfully stops being a fork. It lives in `~/source/philoserf/`.
- **`x3c3/army-memorandum-class` in git history is the pre-transfer name.** Commit
  subjects reference it (e.g. "Merge pull request #49 from x3c3/docs/fork-policy"), and
  GitHub still redirects the old path, so `gh repo view x3c3/...` resolves and looks
  correct. It is the same repo. Always write `philoserf` in new commands.
- **The default branch is `main`** (renamed from `master` on 2026-09-09).
- **There is no `upstream` remote.** It was removed on 2026-09-09; `origin` is the only
  remote. Commands of the form `upstream/...` will fail — treat any you find in older
  notes or commit messages as historical.
- **`main` contains `glallen01/master` as of `ed2082e`** — the last common commit, and
  the base to work from if a curated PR series is ever proposed. Everything after it here
  is this repo's own work. To compare or resume tracking:

  ```sh
  git remote add upstream git@github.com:glallen01/army-memorandum-class.git
  git fetch upstream
  git log --oneline upstream/master..HEAD    # note: glallen01's default is `master`, not `main`
  ```

  Two glallen01 branches were never merged here and are no longer reachable locally:
  `opord-example` (`3d5e5e1`, an OPORD example) and `digsig` (`0aa362d`, superseded by the
  bundled `digsig.sty`). Both remain public on glallen01 and come back with the fetch above.

- **GitHub still classifies this repo as a fork** (`isFork: true`, parent `glallen01`),
  and removing the remote did not change that — it is repo metadata, not a remote. PR and
  issue defaults still point at the parent, so the hazards below remain live.
- **Divergence is documentation and tooling only.** The class itself is unchanged from
  `ed2082e`. The substantive fork work is planned, not landed: it lives as ~49 open
  issues (see Issue tracking).

## Fork policy — do not contact upstream

**Nothing goes to `glallen01/army-memorandum-class` until the divergent work is finished
and deliberately proposed.** Upstream is a separate maintainer's project; unfinished work
arriving there is noise for them, not a contribution.

Removing the `upstream` remote closed off the accidental `git push`, but it did **not**
make this section obsolete: GitHub still treats the repo as a fork, and hazards 1 and 2
below reach glallen01 with no remote configured at all. Hazard 3 applies only if someone
re-adds it.

1. **Pull requests default to the parent.** On GitHub, a PR opened from a fork proposes
   merging into the _upstream_ repo unless you change the base. The `gh` CLI reads this
   from `remote.<name>.gh-resolved` in git config.

   ```sh
   git config --get-regexp gh-resolved    # want: remote.origin.gh-resolved base
   gh repo set-default philoserf/army-memorandum-class   # to fix
   ```

   This was set to `remote.origin.gh-resolved base` on 2026-09-09, replacing a stale
   `remote.upstream` entry. **Run the check above rather than trusting this sentence** —
   git config is not version-controlled, so it drifts per clone and per machine, and a
   fresh clone of this repo starts with no `gh-resolved` at all. A previous revision of
   this file asserted the fix had been applied when it had not; that is the failure mode
   to guard against. Regardless of config, pass an explicit
   `--repo philoserf/army-memorandum-class` on every `gh pr` and `gh issue` command. It
   costs nothing and cannot be misconfigured.

2. **A linked issue URL creates a cross-reference in upstream's timeline**, which
   notifies everyone subscribed to that issue. Writing
   `https://github.com/glallen01/army-memorandum-class/issues/37` in an issue or commit
   message posts an event on their side. Backtick-wrapped text does not — code spans are
   not parsed for references. Refer to upstream issues as `` `glallen01#37` ``.

3. **If you re-add the remote, keep it read-only.** `git fetch` and `gh repo sync` are
   safe — they read. Pushing is what reaches them, and nothing here should ever push to
   an `upstream` ref. Removing the remote (2026-09-09) was what took this hazard off the
   table; re-adding it puts it back.

### Issue tracking

Findings live on the fork:

```sh
gh issue list --repo philoserf/army-memorandum-class
```

They came from a recorded audit and reduction review, and carry a `kind:` label —
`audit`, `reduction`, `upstream`, `infra`, or `decision` — plus `severity:*` and
`evidence:*`. Issues labeled `kind:upstream` are read-only mirrors of open upstream
issues: track them here, discuss them upstream, and never treat one as this fork's
original work.

These issues are the backlog of intended divergence — read the relevant one before
"fixing" something in the class, because the analysis is likely already written up there.

### When the work is done

The graduate-to-`philoserf` option has already been taken. What remains is the other
branch: if the work ever warrants it, propose a curated series of PRs upstream — small,
separable, each on a clean branch cut from `ed2082e`, the last commit this repo shares
with glallen01. That requires re-adding the remote (see Repo identity), and is a
deliberate decision, not a routine step.

## Toolchain

- **LuaLaTeX or XeLaTeX is required** — the class uses `fontspec` and calls
  `\setmainfont` / `\setsansfont` directly. pdflatex will not compile it.
- **Times New Roman and Arial must be installed system-wide** or compilation fails.
- `chktex` is the only linter; `latexmk` drives builds; `latexrun` is optional.

**The toolchain is installed** — TeX Live 2026 (`scheme-full`, no docs or sources) went in
on 2026-09-09 under `~/texlive/2026`, user-owned, no sudo (#50). Times New Roman and Arial
both resolve from `/System/Library/Fonts/Supplemental/`, and all four examples build.

**Its binaries are not on a non-interactive shell's `PATH`**, so `command -v lualatex`
comes back empty from a tool shell and the toolchain looks absent. Prepend the bin
directory first:

```sh
export PATH="$HOME/texlive/2026/bin/universal-darwin:$PATH"
```

`latexrun` is not in the tree. The build used to branch on it and always fall through;
that branch is gone, and `latexmk -lualatex` is simply what runs.

**`make check` exits nonzero on `main`** — `chktex` reports 27 warnings against
`armymemo.cls` (spacing, dashes), none of them new. Compare counts rather than expecting
a clean run.

## Commands

```sh
make                # build every examples/*.pdf
make test           # rendering regression harness -- the real check
make golden         # recapture the golden files after an intended output change
make check          # chktex armymemo.cls
make clean          # remove built PDFs and aux files
make proper         # clean + remove *.out

cd examples && latexmk -lualatex example.tex     # build a single example
```

**`make test` is the test suite.** It rebuilds every `examples/*.tex`, extracts
`pdftotext -layout` text and a page count from each PDF, and diffs both against the
committed goldens in `examples/golden/`. For a document class, rendered output *is* the
behavior, so this is the assertion the examples previously lacked. It lives in
`tools/run-tests.sh`, which drives `latexmk` directly and deliberately never invokes
the `Makefile` at all, so a stale-PDF bug in the build could never make the tests pass
when they should fail. (That was not hypothetical: until #12/#38 the class was not a
prerequisite of the PDF rule.)

Two things to know before running it:

- **`make golden` refuses to write** unless two independent builds extract byte-for-byte
  identically. A golden is never hand-edited -- the `.txt` files carry one form feed per
  page, and stripping those silently breaks page-break detection. See
  `examples/golden/README.md` for provenance and the full rule.
- **`chktex` folds into `make test` as a ratchet**, not a gate: it fails only when the
  warning count rises above `CHKTEX_BASELINE` in `tools/run-tests.sh` (currently 29).
  Lower the baseline in the same change that lowers the count.

The harness finds TeX Live on its own when it is not on a non-interactive shell's `PATH`,
probing the standard install layouts newest-first. Set `TEXBIN=/path/to/texlive/bin/<arch>`
to override.

The README shows `latexmk -pdf -pvc -lualatex example.tex`; `-pvc` is continuous-preview
watch mode — drop it for one-shot builds.

There is one `Makefile`, at the repo root. `examples/Makefile` was removed — it was
mostly delegated to, and `check` was defined identically in both.

## Gotchas

- **`examples/*.pdf` are build output, not tracked files.** They were untracked in 2026-09
  per the decision to remove generated artifacts; `examples/golden/` is the tracked
  rendered reference now. `make clean` therefore deletes only build output. Do not commit
  a rebuilt PDF, and do not look for one in a diff -- look at the golden.
- **The README is stale on fonts.** It says the default is Arial; the class sets
  `\setmainfont{Times New Roman}` (armymemo.cls:117) and `\setsansfont{Arial}` (:126), per
  the 4 OCT 24 AR 25-50 update and DAIG guidance documented in `CHANGES.md`. Users
  override with `\setmainfont{Arial}`.
- **Version lives in two places** — the `\ProvidesClass{armymemo}[YYYY/MM/DD X.Y.Z ...]`
  line (armymemo.cls:24, currently `2026/03/29 0.3.0`) and `CHANGES.md`. Bump both.
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
