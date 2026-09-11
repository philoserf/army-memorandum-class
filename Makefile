SRC=$(wildcard examples/*.tex)

.PHONY: all check test golden clean proper

all: armymemo.cls $(SRC)
	cd examples && $(MAKE) all

check: armymemo.cls
	chktex armymemo.cls

# Rendering regression harness: rebuilds every example and diffs the extracted
# text and page count against examples/golden/. Drives latexmk itself rather
# than delegating to examples/Makefile, whose %.pdf rule does not depend on the
# class and would compare stale PDFs.
test:
	@sh tools/run-tests.sh

# Recapture the goldens. Refuses to write unless two builds agree byte for byte.
golden:
	@sh tools/run-tests.sh --update

clean:
	cd examples && $(MAKE) clean

proper: clean
	cd examples && $(MAKE) proper

