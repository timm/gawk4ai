# usage: ... | gawk -f xval.awk [N=1000, SEED=1]
# vim: set et sw=2 ts=2 sts=2 cc=75 :
BEGIN  { N=1000; Seed=1 }
BEGIN  { FS="[ \t]*,[ \t]*"; OFS=","; CONVFMT="%.17g"
         PROCINFO["sorted_in"] = "@ind_num_asc" }
bare() { next }                      
!head  { srand(Seed); head=$0; next }   
       { a[++n]=$0 }
END    { print head
         while (N > 0) { 
           shuffle(); for(i=1;i<=n && N-- >0; i++) print a[i]}}

 function shuffle(   i,j,t) {
  for(i=n; i>1; i--) { 
    j=int(rand()*i)+1; t=a[i]; a[i]=a[j]; a[j]=t } }

function bare() {                   
  sub(/#.*/, "")                       
  gsub(/^[[:space:]]+|[[:space:]]+$/, "") 
  $1 = $1
  return $0 == "" }
