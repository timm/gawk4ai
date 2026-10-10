# usage: make help
SHELL := bash
MOOT  ?= $(HOME)/tmp/moot
C      = $(MOOT)/classify
S     ?= 1

help:   ## show all rules
	@grep -E '^[a-z]+:.*##' Makefile | sed 's/:.*##/\t/'

gawk:   ## install gawk (mac, linux, windows)
	@command -v gawk > /dev/null || case "$$(uname -s)" in \
	  Darwin) brew install gawk ;; \
	  Linux)  sudo apt-get install -y gawk || sudo dnf install -y gawk ;; \
	  *)      winget install GnuWin32.Gawk ;; esac

moot:   ## get the data
	@test -d $(MOOT) || git clone --depth 1 https://github.com/timm/moot $(MOOT)

# shuffle $(1) to s; T = half the rows
split = gawk -f shuffle.awk seed=$(S) $(1) > s; T=$$(( ($$(wc -l < s) - 1) / 2 ))

nb: gawk moot      ## 0. incremental naive Bayes
	tail -n +2 $(C)/soybean.csv | gawk -f nb.awk | gawk -f abcd.awk

disc: gawk moot    ## 1. numeric x: discretize, then nb
	$(call split,$(C)/diabetes.csv); \
	gawk -f disc.awk s s | tail -n +2 | gawk -f nb.awk T=$$T W=$$T | gawk -f abcd.awk

opt: gawk moot     ## 2. good configs: label 25, kNN guesses, check 5
	$(call split,$(MOOT)/optimize/config/SS-K.csv); gawk -f ydist.awk s s > y; \
	(head -1 y; tail -n +2 y | gawk -f some.awk N=25 T=$$T) | \
	gawk -f knnr.awk T=25 | gawk -f rank.awk C=5

num: gawk moot     ## 3. numeric y: mean of raw kNN and a tree
	$(call split,$(MOOT)/regression/autompg.csv); gawk -f disc.awk s s | tail -n +2 > d; \
	paste -d' ' <(gawk -f knnr.awk T=$$T s) <(gawk -f tree.awk T=$$T d) | \
	gawk '{ d = ($$1+$$3)/2 - $$2; e += d<0 ? -d : d } END { print "MAE", e/NR }'

twcnb: gawk moot   ## 4. rare classes: tf-idf + TWCNB on text
	gawk -f tsv.awk $(MOOT)/text_mining/reading/raw/Kitchenham.csv > k; \
	$(call split,k); gawk -f tfidf.awk s s > c; \
	gawk -f twcnb.awk T=$$T c | gawk -f abcd.awk

all: nb disc opt num twcnb  ## run everything
