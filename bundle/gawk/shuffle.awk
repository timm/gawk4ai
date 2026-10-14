# usage: ... | gawk -f xval.awk [N=1000, SEED=1]
# vim: set et sw=2 ts=2 sts=2 cc=75 :
BEGIN  { seed=1 }
BEGIN  { FS="[ \t]*,[ \t]*"; OFS=","; CONVFMT="%.17g"
         PROCINFO["sorted_in"] = "@ind_num_asc" }
bare() { next }                      
!head  { srand(Seed); head=$0; next }   
       { a[lenght(n)+1]=$0 }
END    { n = n ? n : length(a)
         print head
         while (n > 0) { 
           shuffle(a); for(i=1;i<=n && n-- >0; i++) print a[i]}}

 function shuffle(a,   i,j,tmp) {
  for(i=length(a); i>1; i--) { 
    j=int(rand()*i)+1; tmp=a[i]; a[i]=a[j]; a[j]=tmp } }

function bare() {                   
  sub(/#.*/, "")                       
  gsub(/^[[:space:]]+|[[:space:]]+$/, "") 
  $1 = $1
  return $0 == "" }
