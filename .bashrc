#add all this in your .bashrc file
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin


function subenum(){
	subfinder -d $1 -all | tee domains.$1.txt
	assestfinder --subs-only $1 | tee -a domains.$1.txt
	domained -d $1 --noeyewitness 
	cat domains.$1.txt | while read i; do ctfr -d $i -o $i.ctfr; done 
	curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$1&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u | tee -a domains.$1.txt
	curl -sk "https://crt.sh/?q=%.$1&output=json" | tr ',' '\n' | awk -F'"' '/name_value/ {gsub(/\*\./, "", $4); gsub(/\\n/,"\n",$4);print $4}' | tee -a domains.$1.txt
	cat domains.$1.txt | sort -u | uniq | tee $1_unique
	altdns -i $1_unique -o $1.known -w /home/ubuntu/altdns.txt -r -s $1.resolved

}

function virtualhost()
{
	vhost --ip=$1 --host=$2 --wordlist=/home/ubuntu/virtual-host-discover/wordlist --output=$2.txt | grep $2 | cut -d " " -f2 | cut -d "/" -f 3 | grep -v __cf_bm | grep -v = | grep $2
}

function sublist()
{
	cat $1 | while read i; do subenum $i; done 
}

function alive()
{
	cat $1 | httpx --ports "80,443,3000,3001,3306,21,444,8080,8443,8888,8082,8888,9000,9001,9002" | tee $1.alive
	cat $1.alive | csp -c 20 | tee $1.csp
} 

function slacknotify(){
	nuclei -t /home/ubuntu/nuclei-templates -l $1 --severity low,medium,high,critical -c 100 -o $1.nuclei | notify -silent
}


function getdirs(){
	ffuf -w $1:URL -w /home/ubuntu/words.txt:WORD -u URL/WORD -t 100 -o  $1.dirs -H "Host: localhost"  -s  -mc 200,301,302,401,403
}

function tldenum(){
	tld  -n -d $1 -i /home/ubuntu/tld_scanner/topTLDs.txt -o $1.tld
	cat $1.tld | tr ':' '\n' | grep $1 | cut -d "/" -f 3 | cut -d '"' -f1 | tee $1.tld2
	rm $1.tld
	mv $1.tld2 $1.tld
	cat $1.tld | while read i; do subenum $i ;done 
}

function gitauto()
{
	gitgraber -k /home/ubuntu/tool/gitGraber/wordlists/keywords.txt -q $1 -s
}
