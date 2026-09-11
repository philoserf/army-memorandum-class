# Build and check armymemo.cls and its examples.
#
# There is one Makefile. The examples used to carry their own, which this file
# mostly delegated to, and `check` was defined identically in both.

SRC = $(wildcard examples/*.tex)
PDF = $(SRC:.tex=.pdf)

# Bounded, not the unbounded -j this used to request: thirteen examples against
# unlimited parallelism can race on a cold luaotfload font-names cache.
MAKEFLAGS += -j4

.PHONY: all check test golden clean proper

all: $(PDF)

# The class and the bundled package are real prerequisites, so editing either
# rebuilds the PDFs. They were previously prerequisites of `all` rather than of
# the pattern rule, which meant a class change left every PDF stale and
# `make clean && make` was the documented workaround. It no longer is.
#
# latexmk runs with cwd=examples so the examples' relative paths resolve --
# \documentclass{../armymemo}, \logo{../DOW-Seal-BW} and the symlinks beside them.
examples/%.pdf: examples/%.tex armymemo.cls digsig.sty
	cd examples && latexmk -lualatex $(notdir $<)

check: armymemo.cls
	chktex armymemo.cls

# Rendering regression harness: rebuilds every example and diffs the extracted
# text, page count and class diagnostics against examples/golden/. It drives
# latexmk itself rather than going through this file, so that a stale-PDF bug
# here could never make the tests pass when they should fail.
test:
	@sh tools/run-tests.sh

# Recapture the goldens. Refuses to write unless two builds agree byte for byte.
golden:
	@sh tools/run-tests.sh --update

# example*.pdf is deliberately narrower than *.pdf: DODb1.pdf in that directory is
# a tracked symlink to build input, not output.
clean:
	-rm -f examples/example*.pdf
	-cd examples && rm -f *-blx.bib *.aux *.bbl *.bcf *.blg *.brf *.dvi \
		*.ent *.fdb_latexmk *.fls *.idx *.ilg *.ind *.lof *.log \
		*.lot *.orig *.rtf *.run.xml *.toc *.url

proper: clean
	-rm -f examples/*.out
