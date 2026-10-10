# usage: gawk -f split.awk [Seed=1 N=0] f   (was shuffle.awk + some.awk)
# shuffle, tag rows train/test; N>0 labels just N. header = not data.
BEGIN { FS=" *, *"; OFS=","; Seed=1; CONVFMT="%.17g" }
      { gsub(/^ +| +$/, ""); $1=$1 }  # one clean form for all
NR==1 { srand(Seed); print "header," $0; next }
      { a[rand()] = $0 }
END   { h = int((NR-1)/2); m = N ? N : h
        for (i in a)
          if (++j <= m)   print "train," a[i]
          else if (j > h) print "test,"  a[i] }
