# usage: make help
SHELL := bash
MOOT  ?= $(HOME)/tmp/moot
C      = $(MOOT)/classify
S     ?= 1
G      = gawk -f

help:   ## show all rules
	@grep -E '^[a-z]+:.*##' Makefile | sed 's/:.*##/\t/'

gawk:   ## install gawk (mac, linux, windows)
	@command -v gawk > /dev/null || case "$$(uname -s)" in \
	  Darwin) brew install gawk ;; \
	  Linux)  sudo apt-get install -y gawk || sudo dnf install -y gawk ;; \
	  *)      winget install GnuWin32.Gawk ;; esac

moot:   ## get the data
	@test -d $(MOOT) || git clone --depth 1 https://github.com/timm/moot $(MOOT)

shuffled: gawk moot
	@cat $C/weather.csv | $G shuffle.awk N=20

nb: gawk moot      ## 0. naive Bayes
	$G shuf.awk Seed=$S $C/soybean.csv \
	  | $G bins.awk | $G nb.awk | $G abcd.awk

disc: gawk moot    ## 1. numeric x: bins buckets them, then nb
	$G shuf.awk Seed=$S $C/diabetes.csv \
	  | $G bins.awk | $G nb.awk | $G abcd.awk

opt: gawk moot     ## 2. good configs: label 25, kNN guesses, check 5
	$G split.awk Seed=$S N=25 $(MOOT)/optimize/config/SS-K.csv \
	  | $G ydist.awk | $G knnr.awk | $G rank.awk

twcnb: gawk moot   ## 3. rare classes: tf-idf + TWCNB on text
	$G tsv.awk $(MOOT)/text_mining/reading/raw/Kitchenham.csv \
	  | $G split.awk Seed=$S | $G tfidf.awk | $G twcnb.awk | $G abcd.awk

all: nb disc opt twcnb  ## run everything
