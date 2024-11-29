#! /bin/bash

linked_discovery(){
    echo -e "${BOLD}${GREEN}[*]running hakrawler..."
    echo https://$1 | hakrawler -subs > hakrawler.txt 
    echo -e "${BOLD}${GREEN}[*]got results of hakrawler..."
    echo -e "${BOLD}${GREEN}[*]appending results to site_urls.txt"
    cat hakrawler.txt >> "${output_path}site_urls.txt" && rm hakrawler.txt
}

scraping(){
    > "${3}subdomains.txt"
    ##########ASSETFINDER#############
    echo -e "${BOLD}${RED}[*]running assetfinder....${NC}"
    assetfinder --subs-only $1 >> "${3}subdomains.txt"
    echo -e "${BOLD}${RED}[*]added subdomains to subdomain.txt"

    ###subfinder##########################
    echo -e "${BOLD}${BLUE}[*]running subfinder...${NC}"
    subfinder -d "$1" -o subfinder.txt && cat subfinder.txt >> "${3}subdomains.txt" && \
    rm subfinder.txt
    echo -e "${BOLD}${BLUE}[*]added subdomains to subdomain.txt"

    ### sublister #########################
    echo -e "${BOLD}${YELLOW}[*]running sublist3r...${NC}"
    sublist3r -d $1 -t 50 -o sublist3r.txt && cat sublist3r.txt >> "${3}subdomains.txt" && \
    rm sublist3r.txt
    echo -e "${BOLD}${YELLOW}[*]added subdomains to subdomain.txt"

    #########SUBSCRAPER###################
    echo -e "${BOLD}${YELLOW}r[*]unning subscraper...${NC}"
    (
        cd /home/kali/subscraper && \
        source env/bin/activate
        python3 subscraper.py -d $1 -o subscraper.txt && \
        deactivate && \
        cat subscraper.txt >> "${3}subdomains.txt" && \
        rm subscraper.txt
        echo -e "${BOLD}${YELLOW}[*]adding subdomains to subdomain.txt"
    )
    (
        echo -e "${BOLD}${RED}[*]sorting subdomains and running httprobe ..."
        cd $3 && sort -u subdomains.txt > uniqueSubdomains.txt && \
        cat "${3}uniqueSubdomains.txt" | httprobe -c 80 --prefer-https > actualSites.txt 
    )
}

brute_forcing(){
    echo -e "${BOLD}${BLUE}[*]running gobuster in brute forc mode...${NC}"
    > gobuster.txt
    gobuster dns -d $1 --wordlist /home/kali/n0kovo_subdomains/n0kovo_subdomains_small.txt --wildcard -t 50 -o gobuster.txt 
    echo -e "${BOLD}${BLUE}[*]parsing results...${NC}"
    sed 's/\x1b\[[0-9;]*m//g' gobuster.txt | grep -oP '(?<=Found: ).*?\.[a-zA-Z0-9.-]+\.[a-z]{2,}' > "${3}gobuster_parsed.txt"
}
