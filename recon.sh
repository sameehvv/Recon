#!/bin/bash

#correct syntax
if [ "$1" == "" ]
then
    echo "[+]Syntax:- $0 example.com"
else

    url=$1

    #making directory
    mkdir $url

    #gathering the subdomains
    echo "[+]Gathering subdomains using assetfinder"
    assetfinder -subs-only $url >> subs.txt
    echo "Done"

    echo "[+]Gathering subdomains using subfinder"
    subfinder -d $url -silent >> subs.txt
    echo "Done"

    echo "[+]Gathering subdomains using amass"
    amass enum -norecursive -noalts -d $url >> subs.txt
    echo "Done"

    echo -e "\n[+]Found $(cat subs.txt | wc -l) subdomains"
     
    #finding the alive domains
    echo -e "\n[+]Finding live subdomains"
    cat subs.txt | httprobe >> alive.txt
     
    #deduplicates and sorting
    while read line; do
        echo ${line#*://} >> newlist.txt
    done < alive.txt

    cat newlist.txt | sort -u >> $url/subdomains.txt
    echo "$(cat $url/subdomains.txt | wc -l) subdomains found"

    #subdomains takeoever
    echo -e "\n[+]Testing subdomains takeover"
    subjack -w $url/subdomains.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> $url/takeover.txt
    echo "Done"

    #fetch URLs
    echo -e "\n[+]Fetching URLs"
    cat $url/subdomains.txt | waybackurls >> waybackdata.txt
    cat $url/subdomains.txt | gau >> gaudata.txt
    cat waybackdata.txt gaudata.txt | sort -u >> $url/urls.txt   
    echo "Done"

    #aquatone
    echo -e "\n[+]Running aquatone on subdomains"
    cat $url/subdomains.txt | aquatone -out $url/aquatone
    echo "Done"

    echo "All files saved to '$url' folder"

    #removing unwanted files
    rm subs.txt alive.txt newlist.txt 
fi
