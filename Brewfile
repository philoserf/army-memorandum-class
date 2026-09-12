# Tooling this repository needs, pinned to the repository rather than to a
# machine.
#
#     brew bundle                      # install everything below
#     brew bundle check --no-upgrade   # is it all installed? install nothing
#
# Use --no-upgrade for that check. Without it, `brew bundle check` also fails on
# any formula that is merely *outdated*, reporting "needs to be installed or
# updated" for something already present and working -- which is a confusing
# answer to the question "can I build this repo?".
#
# Several of these also appear in the maintainer's global ~/.Brewfile. That is
# not a reason to leave them out: a global Brewfile describes one person's
# machine today, and this file describes what a clone needs in order to build,
# test and lint. A contributor has a different global, and so does the
# maintainer after the next reinstall.
#
# What is deliberately NOT here: TeX Live. lualatex, latexmk and chktex come
# from a TeX Live installation (scheme-full, under ~/texlive), which Homebrew
# does not manage and which `tools/run-tests.sh` probes for by itself. See
# CLAUDE.md for the install and the PATH export.

# The build driver. `task --list` is the entry point to everything else.
brew "go-task"

# pdftotext and pdfinfo are what the rendering regression harness compares --
# `task test` cannot run without them -- and pdfimages/pdftoppm back
# tools/extract-ar-figures.py and the visual diffing described in
# references/README.md. TeX Live does NOT ship these, despite being the source
# of everything else in the build; they are Poppler's.
brew "poppler"

# `task lint` and `task format`, in the order the lint task runs them.
brew "uv"          # provides uvx, which fetches and runs ruff without installing it
brew "shellcheck"  # POSIX sh correctness for tools/run-tests.sh
brew "shfmt"       # shell formatting, run with no style flags -- see Taskfile.yml
brew "latexindent" # LaTeX formatting. NOT the TeX Live copy, whose Perl
# dependencies are missing; see the LATEXINDENT var in Taskfile.yml
brew "prettier" # Markdown and YAML
