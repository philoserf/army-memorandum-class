#!/bin/sh
# Rendering regression harness for armymemo.cls.
#
#   .tex -> PDF -> pdftotext -layout -> diff against examples/golden/
#
# For a document class, rendered output *is* the behavior: there is nothing
# meaningful to unit test below this level. See issue #51.
#
# Usage:
#   tools/run-tests.sh              compare against the committed goldens
#   tools/run-tests.sh --update     recapture the goldens (determinism-gated)
#   tools/run-tests.sh --determinism  check reproducibility without writing
#
# Written for POSIX sh: make's default SHELL is /bin/sh, and a subset of both
# sh and zsh is the only thing safe to rely on here. BSD userland, so no GNU-only
# flags anywhere.

set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
EX="$ROOT/examples"
GOLDEN="$EX/golden"
WORK="$ROOT/.test-work"

# chktex reports this many warnings on a clean tree. The harness fails only when
# the count *rises*, so new lint is caught without demanding the backlog be fixed
# first. Milestone 2 cleanups should ratchet this down.
CHKTEX_BASELINE=29

# The distinctive token emitted by the font fallback guard (#14). Deliberately not
# a generic "Class army-memo Warning" match: \am@MissingRequiredArgWarning emits
# that same prefix for legitimately missing optional fields.
FALLBACK_TOKEN='falling back to TeX Gyre'

MODE=compare
case "${1:-}" in
    --update)      MODE=update ;;
    --determinism) MODE=determinism ;;
    "")            ;;
    *)             echo "usage: $0 [--update|--determinism]" >&2; exit 2 ;;
esac

# ---------------------------------------------------------------- toolchain ---
# TeX Live is frequently not on a non-interactive shell's PATH. Probe the standard
# install layouts, newest first. TEXBIN overrides. Nothing machine-specific is
# committed -- these are the documented locations, not one person's path.
if ! command -v lualatex >/dev/null 2>&1; then
    for d in ${TEXBIN:-} /Library/TeX/texbin \
        $(printf '%s\n' "$HOME"/texlive/*/bin/* /usr/local/texlive/*/bin/* \
            /opt/texlive/*/bin/* 2>/dev/null | sort -r); do
        if [ -x "$d/lualatex" ]; then
            PATH="$d:$PATH"
            export PATH
            echo "toolchain: $d"
            break
        fi
    done
fi

for t in lualatex latexmk pdftotext pdfinfo chktex; do
    if ! command -v "$t" >/dev/null 2>&1; then
        echo "error: $t not found." >&2
        echo "       Set TEXBIN=/path/to/texlive/bin/<arch> if TeX Live is installed" >&2
        echo "       somewhere non-standard." >&2
        exit 127
    fi
done

# ------------------------------------------------------------------- guards ---
# A \today in an example renders the build date into the extracted text, so its
# golden would differ the next day. Catch it here rather than as a confusing
# "nondeterministic" report later. See issue #10.
if grep -l '\\today' "$EX"/*.tex >/dev/null 2>&1; then
    printf 'error: \\today found in an example; its golden would be unstable (#10):\n' >&2
    grep -n '\\today' "$EX"/*.tex >&2
    exit 1
fi

examples() {
    for tex in "$EX"/*.tex; do
        basename "$tex" .tex
    done
}

# ----------------------------------------------------------------- building ---
# latexmk is driven directly, one file at a time, and examples/Makefile is never
# invoked: it sets an unbounded MAKEFLAGS=-j, and its %.pdf rule does not list the
# class as a prerequisite, so it would happily compare stale PDFs and pass when it
# should fail. -g forces a rebuild regardless of timestamps.
build_and_extract() {
    dest=$1
    mkdir -p "$dest"
    rc=0

    for b in $(examples); do
        if ! (cd "$EX" && latexmk -lualatex -g -interaction=nonstopmode "$b.tex") \
            >"$dest/$b.build.log" 2>&1; then
            echo "FAIL $b: build failed" >&2
            tail -25 "$dest/$b.build.log" | sed 's/^/    /' >&2
            rc=1
            continue
        fi

        # A golden captured while the fallback fonts are active would record the
        # wrong typeface. TeX Gyre is metric-compatible with Times and Helvetica,
        # so the text diff alone cannot see this -- only the log can.
        if [ -f "$EX/$b.log" ] && grep -q "$FALLBACK_TOKEN" "$EX/$b.log"; then
            echo "FAIL $b: font fallback active -- Times New Roman or Arial is missing." >&2
            echo "    Goldens must be captured with the real AR 25-50 fonts (#14)." >&2
            rc=1
            continue
        fi

        pdftotext -layout "$EX/$b.pdf" "$dest/$b.txt"
        pdfinfo "$EX/$b.pdf" | awk '/^Pages:/ { print $2 }' >"$dest/$b.pages"
    done

    # latexmk leaves auxiliary files beside the sources; the PDFs themselves are
    # gitignored build output and are left in place, as a plain `make` would.
    (cd "$EX" && rm -f ./*.aux ./*.fdb_latexmk ./*.fls ./*.log ./*.out ./*.toc)

    return $rc
}

# Two independent builds must extract byte-identically before a golden is worth
# committing. Without the forced rebuild in build_and_extract this would compare
# a PDF to itself and prove nothing.
check_determinism() {
    rm -rf "$WORK/a" "$WORK/b"
    echo "determinism: first build"
    build_and_extract "$WORK/a"
    echo "determinism: second build"
    build_and_extract "$WORK/b"

    drift=0
    for b in $(examples); do
        cmp -s "$WORK/a/$b.txt" "$WORK/b/$b.txt" ||
            { echo "NONDETERMINISTIC $b: extracted text differs between builds"; drift=1; }
        cmp -s "$WORK/a/$b.pages" "$WORK/b/$b.pages" ||
            { echo "NONDETERMINISTIC $b: page count differs between builds"; drift=1; }
    done
    return $drift
}

# ------------------------------------------------------------------- chktex ---
run_chktex() {
    n=$(chktex "$ROOT/armymemo.cls" 2>/dev/null | grep -c '^Warning' || true)
    if [ "$n" -gt "$CHKTEX_BASELINE" ]; then
        echo "FAIL chktex: $n warnings, above the baseline of $CHKTEX_BASELINE"
        echo "    New lint was introduced. Fix it, or lower nothing -- the baseline"
        echo "    only ratchets down."
        return 1
    fi
    if [ "$n" -lt "$CHKTEX_BASELINE" ]; then
        echo "ok   chktex ($n warnings, below the baseline of $CHKTEX_BASELINE --"
        echo "     lower CHKTEX_BASELINE in $0 to lock the improvement in)"
        return 0
    fi
    echo "ok   chktex ($n warnings, at baseline)"
    return 0
}

# --------------------------------------------------------------------- main ---
mkdir -p "$WORK"

case "$MODE" in
    determinism)
        if check_determinism; then
            echo "PASS: output is reproducible across builds"
            exit 0
        fi
        echo "FAILED"
        exit 1
        ;;

    update)
        if ! check_determinism; then
            echo "refusing to write goldens: output is not reproducible" >&2
            exit 1
        fi
        mkdir -p "$GOLDEN"
        for b in $(examples); do
            cp "$WORK/a/$b.txt" "$GOLDEN/$b.txt"
            cp "$WORK/a/$b.pages" "$GOLDEN/$b.pages"
        done
        echo "goldens updated in $GOLDEN"
        echo "review 'git diff examples/golden/' before committing"
        exit 0
        ;;
esac

# compare
rm -rf "$WORK/run"
build_ok=0
build_and_extract "$WORK/run" || build_ok=1

fail=$build_ok
for b in $(examples); do
    [ -f "$WORK/run/$b.txt" ] || continue # build already reported

    if [ ! -f "$GOLDEN/$b.txt" ]; then
        echo "FAIL $b: no golden file (run 'make golden')"
        fail=1
        continue
    fi

    bad=0
    want=$(cat "$GOLDEN/$b.pages")
    got=$(cat "$WORK/run/$b.pages")
    if [ "$want" != "$got" ]; then
        echo "FAIL $b: page count $want -> $got"
        bad=1
    fi

    if ! diff -u "$GOLDEN/$b.txt" "$WORK/run/$b.txt" >"$WORK/$b.diff"; then
        echo "FAIL $b: rendered text changed"
        sed -n '1,40p' "$WORK/$b.diff" | sed 's/^/    /'
        echo "    (full diff: .test-work/$b.diff)"
        bad=1
    fi

    if [ "$bad" -eq 0 ]; then
        echo "ok   $b ($got pages)"
    else
        fail=1
    fi
done

run_chktex || fail=1

if [ "$fail" -ne 0 ]; then
    echo "FAILED"
    exit 1
fi
echo "PASS"
