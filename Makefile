# usage: make help
SHELL  := bash
CHROME ?= /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

help:   ## show all rules
	@grep -E '^[a-z]+:.*##' Makefile | sed 's/:.*##/\t/'

slides: ## slides/*.html -> slide*.png (1920x1080)
	@python3 slides/build.py
	@for f in slides/out/slide*.html; do n=$$(basename $$f .html); \
	  "$(CHROME)" --headless --disable-gpu --hide-scrollbars \
	    --force-device-scale-factor=1 --window-size=1920,1080 \
	    --virtual-time-budget=2000 --screenshot=$$n.png "file://$(PWD)/$$f" \
	    2> /dev/null; echo "$$n.png"; done

.PHONY: help slides fig big

fig:    ## rerun the slide experiments and line counts (needs MOOT data)
	@python3 slides/rank.py
	@python3 slides/curve.py
	@python3 slides/loc.py

big:    ## the long one: 67 files x 20 shuffles, gawk vs LightGBM
	@python3 slides/small.py -a
