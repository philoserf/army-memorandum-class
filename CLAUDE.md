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
- **Divergence is now substantive and landed in the class itself.** This was not true
  until 2026-09-11, and an earlier revision of this file said the opposite. `armymemo.cls`
  is +515/-215 against `ed2082e`: the closing block, classification marks, head sizing,
  option order, font fallback, list depth, several never-firing guards and the public API
  surface have all changed, across six milestones released as `0.4.0`. The audit backlog
  that described this work is closed. Treat `ed2082e` as a divergence point, not as a
  description of the current class — and count open issues with `gh` rather than trusting a
  number written here, which is how the previous "~49 open issues" went stale.

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
- **`task lint` is every linter that can gate**: `ruff` over the Python (via `uvx`; not
  installed), `shellcheck` and `shfmt -d` over the shell, and `latexindent -k` over
  `armymemo.cls` and the examples. `task format` is the writing half.
- **`chktex` is deliberately not in `lint`.** It reports 26 warnings on `main`, so it would
  make the gate permanently red. It lives in `check` (advisory) and in `test` (ratcheted
  against `CHKTEX_BASELINE`, failing only when the count rises).
- **`lacheck` was evaluated and rejected.** It has no concept of a `.cls`: all 19 findings
  here are "Do not use @ in LaTeX macro names", which is exactly what an internal `am@`
  macro must do. Its one finding on an example is a false positive too (`~~`, the AR's
  required spacing). A linter that only fires on correct code is worse than none.
- **latexindent must come from Homebrew, not TeX Live.** TeX Live ships it as a Perl script
  without its dependencies (`YAML::Tiny`, `File::HomeDir`, …), so it aborts with exit 2 —
  and since this repo's own instructions prepend the TeX Live bin directory to `PATH`, that
  broken copy comes *first*. The `LATEXINDENT` var in `Taskfile.yml` probes by `--version`
  and picks one that runs, the same way `tools/run-tests.sh` probes for TeX Live.
- **Every formatter here runs on its own defaults.** `ruff.toml` carries
  `select = ["ALL"]` with a short, justified ignore list and restates no ruff default;
  latexindent and shfmt are given no style flags at all, so `tools/run-tests.sh` is tab
  indented with `case` arms at column zero and the LaTeX is tab indented, because that is
  what those tools do unprompted. There is deliberately no `.editorconfig`. If you add
  style flags to either formatter without reformatting the files in the same change, the
  `lint` gate will start failing on correct code.

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

**`task check` exits nonzero on `main`** — `chktex` reports 26 warnings against
`armymemo.cls` (spacing, dashes), none of them new. Compare counts rather than expecting
a clean run. Note the exit *code* is 201, not chktex's own 2: go-task reports a failed
command with its own status. Nothing scripts on it — the ratchet in `tools/run-tests.sh`
runs `chktex` itself — but do not assert on 2.

## Commands

Builds are driven by **go-task** (`Taskfile.yml`, version 3), not make — the Makefile was
removed in the conversion. `task --list` prints the current set.

```sh
task                # build every examples/*.pdf (alias: task build)
task test           # rendering regression harness -- the real check
task golden         # recapture the golden files after an intended output change
task check          # chktex armymemo.cls (advisory; always nonzero on main)
task lint           # every gating linter: ruff, shellcheck, shfmt, latexindent -k
task format         # reformat armymemo.cls and the examples with latexindent
task clean          # remove built PDFs and aux files
task proper         # clean + remove *.out

cd examples && latexmk -lualatex example.tex     # build a single example
```

**Up-to-date checks are by checksum, not mtime.** `make` rebuilt on a newer timestamp;
`task` compares file contents, so `touch armymemo.cls` no longer forces a rebuild while a
real edit still does. `armymemo.cls` and `digsig.sty` are listed as `sources:` of the
per-example `build:one` task, so editing either rebuilds all twenty PDFs — that is the
#12/#38 fix, and dropping them from that list silently restores the bug. Fingerprints live
in `.task/`, which is ignored and safe to delete; doing so forces one full rebuild.

**`task test` is the test suite.** It rebuilds every `examples/*.tex`, extracts
`pdftotext -layout` text and a page count from each PDF, and diffs both against the
committed goldens in `examples/golden/`. For a document class, rendered output *is* the
behavior, so this is the assertion the examples previously lacked. It lives in
`tools/run-tests.sh`, which drives `latexmk` directly and deliberately never invokes
the `Taskfile` at all, so a stale-PDF bug in the build could never make the tests pass
when they should fail. (That was not hypothetical: until #12/#38 the class was not a
prerequisite of the PDF rule.) Do not "simplify" `test` into a dependency on `build`.

Two things to know before running it:

- **`task golden` refuses to write** unless two independent builds extract byte-for-byte
  identically. A golden is never hand-edited -- the `.txt` files carry one form feed per
  page, and stripping those silently breaks page-break detection. See
  `examples/golden/README.md` for provenance and the full rule.
- **`chktex` folds into `task test` as a ratchet**, not a gate: it fails only when the
  warning count rises above `CHKTEX_BASELINE` in `tools/run-tests.sh` (currently 26).
  Lower the baseline in the same change that lowers the count.

The harness finds TeX Live on its own when it is not on a non-interactive shell's `PATH`,
probing the standard install layouts newest-first. Set `TEXBIN=/path/to/texlive/bin/<arch>`
to override.

The README shows `latexmk -pdf -pvc -lualatex example.tex`; `-pvc` is continuous-preview
watch mode — drop it for one-shot builds.

There is one `Taskfile.yml`, at the repo root. Before it there was one `Makefile` in the
same place, and before that an `examples/Makefile` as well — mostly delegated to, with
`check` defined identically in both.

## Gotchas

- **`examples/*.pdf` are build output, not tracked files.** They were untracked in 2026-09
  per the decision to remove generated artifacts; `examples/golden/` is the tracked
  rendered reference now. `task clean` therefore deletes only build output. Do not commit
  a rebuilt PDF, and do not look for one in a diff -- look at the golden.
- **The README is stale on fonts.** It says the default is Arial; the class sets
  `\setmainfont{Times New Roman}` (armymemo.cls:117) and `\setsansfont{Arial}` (:126), per
  the 4 OCT 24 AR 25-50 update and DAIG guidance documented in `CHANGES.md`. Users
  override with `\setmainfont{Arial}`.
- **Version lives in two places** — the `\ProvidesClass{armymemo}[YYYY/MM/DD X.Y.Z ...]`
  line (armymemo.cls:28, currently `2026/09/11 0.4.0`) and `CHANGES.md`. Bump both.
- `examples/armymemo.cls`, `examples/digsig.sty`, and `examples/DODb1.pdf` are symlinks to
  the repo root, so the examples always compile against the live class.

## Architecture

The class loads KOMA-Script `scrartcl` and does nearly all its work in two hooks:

- `\AtBeginDocument` — logo and the DOD letterhead block.
- `shipout/background` (kernel hook, hence `\NeedsTeXFormat{LaTeX2e}[2020/10/01]`) —
  the classification marks, top and bottom of every page. Inside that hook the origin
  is the paper's top-left corner, so `\am@classmark` positions against
  `\paperwidth`/`\paperheight` and needs no `remember picture`. Its `inner sep=0pt` is
  load-bearing: TikZ's default is `0.3333em`, which would make the marks' distance from
  the paper edge follow the ambient font size.
- `\AtEndDocument` — `\am@closing` (authority line, the reserved signing space, and a
  two-column `\parbox` row: enclosures left, signature right), then distribution and
  copies-furnished in normal flow.

  **The closing is one unbreakable box on purpose.** The page builder can measure a
  `\parbox`, so it fits the whole closing or moves all of it, as AR 25-50 requires. It
  used to be a zero-height `tikzpicture` overlay at `0.5\textwidth`; occupying no
  vertical space, it could not be broken around, and the enclosure list merely happened
  to land beside it. Distribution and copies-furnished stay *outside* the box — a
  `\parbox` cannot break across a page and those lists must be able to; `\Needspace*`
  keeps each heading with its first entries instead.

The document body itself is just a relabeled `enumerate`: `enumitem` re-declares it to
**depth 5** with AR-style labels `1.` / `a.` / `(1)` / `(a)` (armymemo.cls:136-137).
Authors write nested lists, not sections.

Five, not four, is deliberate and not a typo for the AR's limit. AR 25-50 figure 2-1 says
"do not subdivide beyond the third subdivision" — four usable levels — but at a *declared*
depth of four, enumitem answers a fifth level with its own "Too deeply nested" error, which
names nothing useful. Declaring five lets level 5 exist just long enough for the class to
say which rule was broken; level 6 is a hard enumitem error again, which is the right
answer for someone who ignored the warning. Figure 2-1 also caps the *indent* — "do not
indent any further than the second subdivision" — which is why `\setlist[3]` and
`\setlist[4]` share `itemindent=0.75in` rather than stepping.

**Metadata pattern.** Every user-facing field follows one of two shapes:

- _Scalar_: `\officesymbol{...}` → `\def\am@officesymbol{...}`, with a default set by
  invoking the setter immediately after definition. Required fields default to
  `\am@MissingRequiredArgError` / `...Warning`, which emit a build error or warning _and_
  substitute a visible placeholder (`OFFICE SYMBOL`, `DRAFT`) into the output.
- _List_: `\address`, `\addencl`, `\adddistro`, `\addcf`, `\memoline` / `\multimemofor` /
  `\multimemothru` use etoolbox `\listadd` into `\am@list@*`, rendered by an `\am@*` loop
  inside the appropriate hook. Only enclosures still keep a counter (`am@encl@count`);
  the rest test the list itself with `\ifdefvoid`. `\addmemoline` is a retained alias for
  `\memoline` -- it is the name that matches this family, but `\memoline` is the one the
  README documents and every example uses, so that is the canonical spelling.

Adding a new field means: define the setter, store into an `am@`-prefixed internal, and
render it from the correct hook. The renderers vary output between zero, one, and many
entries; the enclosure counter survives because its output names the number (`Encl` vs
`2 Encls`; `\enclsnocount` suppresses the count per AR 25-50 Figure 4-4), while the other
lists only need to know whether they are empty.

**Options.** `digsig` is the only class-specific option — it sets an etoolbox bool and
loads the bundled `digsig.sty`, which adds an interactive PDF signature field to the
signature block. Everything else is passed through to `scrartcl` via `\DeclareOption*`.

`am@`-prefixed macros are internal — a document can't reach them without `\makeatletter`.
Everything else is public API.
