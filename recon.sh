#!/bin/bash

#correct syntax
if [ "$1" == "" ]
then
    echo "[+]Syntax:- $0 example.com"
else

    #making directory
    mkdir $1'_recon'

    #gathering the subdomains
    echo "[+]Gathering subdomains using assetfinder"
    assetfinder -subs-only $1 >> subs.txt
    echo "Done"

    echo "[+]Gathering subdomains using subfinder"
    subfinder -d $1 -silent >> subs.txt
    echo "Done"

    echo "[+]Gathering subdomains using amass"
    amass enum -norecursive -noalts -d $1 >> subs.txt
    echo "Done"

    echo -e "\n[+]Found $(cat subs.txt | wc -l) subdomains"
     
    #finding the alive domains
    echo -e "\n[+]Finding live subdomains"
    cat subs.txt | httprobe >> alive.txt
     
    #deduplicates and sorting
    while read line; do
        echo ${line#*://} >> newlist.txt
    done < alive.txt

    cat newlist.txt | sort -u >> $1'_recon'/subdomains.txt
    echo "$(cat $1'_recon'/subdomains.txt | wc -l) subdomains found"

    #subdomains takeoever
    echo -e "\n[+]Testing subdomains takeover"
    subjack -w $1'_recon'/subdomains.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 >> $1'_recon'/takeover.txt
    echo "Done"

    #waybackurls
    echo -e "\n[+]Scraping wayback data"
    cat $1'_recon'/subdomains.txt | waybackurls | sort -u >> $1'_recon'/waybackdata.txt   
    echo "Done"

    #aquatone
    echo -e "\n[+]Running aquatone on subdomains"
    cat $1'_recon'/subdomains.txt | aquatone -out $1'_recon'/aquatone
    echo "Done"

    echo "All files saved to '$1_recon' folder"

    #removing unwanted files
    rm subs.txt alive.txt newlist.txt 
fi
