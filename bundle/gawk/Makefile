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

nb: gawk moot      ## 1. naive Bayes
	$G shuf.awk Seed=$S $C/soybean.csv \
	  | $G bins.awk | $G nb.awk | $G abcd.awk

disc: gawk moot    ## 2. numeric x: bins buckets them, then nb
	$G shuf.awk Seed=$S $C/diabetes.csv \
	  | $G bins.awk | $G nb.awk | $G abcd.awk

opt: gawk moot     ## 3. good configs: label 32, check 5, see how good
	$G shuf.awk Seed=$S $(MOOT)/optimize/config/SS-K.csv \
	  | $G rank.awk K=32 C=5

OPT = misc/auto93 process/nasa93dem process/coc1000 process/pom3a \
      process/pom3d process/xomo_flight config/SS-A config/SS-D \
      config/SS-K config/SS-M config/Apache_AllMeasurements \
      config/HSMGP_num config/SQL_AllMeasurements systems/7z \
      systems/BDBC systems/HSQLDB rl/A2C_CartPole sales_data/socks \
      misc/Wine_quality test/dataset120
RK ?= 32
RC ?= 5
R  ?= 20

ranks: gawk moot   ## 3b. rank over $(OPT), $(R) shuffles, median+quartiles
	@printf "%-26s %6s %4s %4s %4s\n" data rows med q25 q75
	@for f in $(OPT); do \
	  for s in $$(seq 1 $(R)); do \
	    $G shuf.awk Seed=$$s $(MOOT)/optimize/$$f.csv \
	    | $G rank.awk K=$(RK) C=$(RC); done \
	  | gawk -v n=$$(basename $$f) -v r=$$(($$(wc -l < $(MOOT)/optimize/$$f.csv) - 1)) \
	    '{a[NR]=$$1} END{k=asort(a); printf "%-26s %6s %4d %4d %4d\n", \
	      n, r, a[int(k/2)], a[int(k*0.25)+1], a[int(k*0.75)]}'; \
	done | sort -k3 -n

twcnb: gawk moot   ## 4. rare classes: tf-idf + TWCNB on text
	@t=$$(mktemp); $G tsv.awk $(MOOT)/text_mining/reading/raw/Kitchenham.csv \
	  | $G split.awk Seed=$S > $$t;  \
	 $G tfidf.awk $$t $$t \
	  | $G twcnb.awk T=$$(grep -c '^train,' $$t) | $G abcd.awk; rm -f $$t

all: nb disc opt twcnb  ## run everything
