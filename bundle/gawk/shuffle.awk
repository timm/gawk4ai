# usage: gawk -f shuffle.awk [seed=1] f    (header stays first)
BEGIN { seed = 1; CONVFMT = "%.17g" }
NR==1 { srand(seed); print; next }
      { a[rand()] = $0 }
END   { for (i in a) print a[i] }
