#! /bin/bash

# Defining the output path
output_path="/home/kali/reconFramework/${2}_recon/"


linked_discovery(){
    echo -e "${BOLD}${GREEN}running hakrawler..."
    echo https://$1 | hakrawler -subs > hakrawler.txt 
    echo -e "${BOLD}${GREEN}got results of hakrawler..."
    echo -e "${BOLD}${GREEN}appending results to site_urls.txt"
    cat hakrawler.txt >> "${output_path}site_urls.txt" && rm hakrawler.txt
}

scraping(){


    ##########ASSETFINDER#############
    echo -e "${BOLD}${RED}running assetfinder....${NC}"
    assetfinder --subs-only $1 -o assetfinder.txt && \
    cat assetfinder.txt >> "${output_path}subdomains.txt" && \
    rm assetfinder.txt
    echo -e "${BOLD}${RED} adding subdomains to subdomain.txt"
    
    #########SUBSCRAPER###################
    echo -e "${BOLD}${YELLOW}running subscraper...${NC}"
    (
        cd /home/kali/subscraper && \
        source env/bin/activate
        python3 subscraper.py -d $1 -o subscraper.txt && \
        deactivate && \
        cat subscraper.txt >> "${output_path}subdomains.txt" && \
        rm subscraper.txt
        echo -e "${BOLD}${YELLOW} adding subdomains to subdomain.txt"
    )

    ###subfinder##########################
    echo -e "${BOLD}${BLUE}running subfinder...${NC}"
    subfinder -d "$1" -o subfinder.txt && cat subfinder.txt >> "${output_path}subdomains.txt" && \
    rm subfinder.txt
    echo -e "${BOLD}${BLUE} added subdomains to subdomain.txt"

    ### sublister #########################
    echo -e "${BOLD}${YELLOW}running sublist3r..."
    sublist3r -d $1 -t 50 -o sublister.txt && cat sublister.txt >> "${output_path}subdomains.txt" && \
    rm sublist3r.txt
     echo -e "${BOLD}${YELLOW} added subdomains to subdomain.txt"
}