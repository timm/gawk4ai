# usage: gawk -f tsv.awk raw.csv   (raw SLR csv -> text<TAB>label)
BEGIN { FPAT = "([^,]*)|(\"([^\"]|\"\")*\")"; OFS = "\t" }
NR==1 { for (i=1; i<=NF; i++) col[$i] = i; print "text", "label!"; next }
      { print unq($col["document_title"]) " " unq($col["abstract"]),
              unq($NF) }

function unq(s) {
  gsub(/^"|"$/, "", s); gsub(/""/, "\"", s); gsub(/[\t\r]/, " ", s)
  return s }
