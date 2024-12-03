#! /bin/bash
BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

domain=""
directory=""



while getopts ":d:ljsbP" opt; do 
    case $opt in
        d)
            domain=$OPTARG
            directory="${domain}_recon"
            output_path="/home/kali/reconFramework/${domain}_recon/"
            ;;
        l)
            linked_discovery_flag=true
            ;;
        s)
            scraping_flag=true
            ;;
        b)
            brute_forcing_flag=true
            ;;
        P)
            port_scanning_flag=true
            ;;
        ?)
            echo "invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        esac
    done

if [ -z "$domain" ]; then
    echo "you must specify a domain with the -d option"
    exit 1 
fi

mkdir -p "$output_path"

source "$(dirname "$0")/scan.sh"


#function calls
if [ "$linked_discovery_flag" = true ]; then
    linked_discovery "$domain" "$directory" "$output_path"
fi

if [ "$scraping_flag" = true ]; then
    scraping "$domain" "$directory" "$output_path"
fi

if [ "$brute_forcing_flag" = true ]; then
    brute_forcing "$domain" "$directory" "$output_path"
fi

if [ "$port_scanning_flag" = true ]; then
    file_path="${output_path}uniqueSubdomains.txt"
    output_file="${output_path}dns_results.txt"

    # Check if input file exists
    if [ ! -f "$file_path" ]; then
        echo -e "${BOLD}${RED}[!] Subdomain file not found: $file_path ${NC}"
        exit 1
    fi

    echo -e "${BOLD}${RED}[*]Finding subdomains IP Adresses...${NC}"
    while read domain; do
        # Error handling in case 'dig' fails
        ip=$(dig +short A "$domain" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
        if [ ! -z "$ip" ]; then
            echo "$ip" >> "$output_file"
        fi
    done < "$file_path"

    echo -e "${BOLD}${BLUE}[*]IP addresses saved to ${output_file}...${NC}"
    masscan_output="${output_path}masscan_results.txt"
    nmap_output="${output_path}nmap_results"
    brutespray_output="${output_path}brutespray_results.txt"

    ####### Masscan
    echo -e "${BOLD}${YELLOW}[*]Running masscan to find open ports...${NC}"
    sudo masscan -p22,3306,21,1433,5432,445,27017,1521,3389 --banners --source-ip 192.168.1.200 -iL "${output_file}" -oL "$masscan_output"
    
    # Check if masscan ran successfully
    if [ $? -ne 0 ]; then
        echo -e "${BOLD}${RED}[!] Masscan failed. Exiting...${NC}"
        exit 1
    fi

    echo -e "${BOLD}${BLUE}[*]Masscan results saved to ${masscan_output} ${NC}"
    
    # Extract cleaned IP addresses
    cat "$masscan_output" | grep -oP '(\d{1,3}\.){3}\d{1,3}' | sort -u > "${output_path}cleaned_masscan_results.txt"

    
    # Check if the cleaned file has results
    if [ ! -s "${output_path}cleaned_masscan_results.txt" ]; then
        echo -e "${BOLD}${RED}[!] No valid IPs found in masscan results. Exiting...${NC}"
        exit 1
    fi

    ###### Nmap
    echo -e "${BOLD}${RED}[*]Running nmap for detailed scanning...${NC}"
    sudo nmap -Pn -sV -iL "${output_path}cleaned_masscan_results.txt" -p22,3306,21,1433,5432,445,27017,1521,3389 -oG "$nmap_output"

    # Check if nmap ran successfully
    if [ $? -ne 0 ]; then
        echo -e "${BOLD}${RED}[!] Nmap failed. Exiting...${NC}"
        exit 1
    fi

    echo -e "${BOLD}${GREEN}[*]Nmap results saved to ${nmap_output} ${NC}"

    ##### Brutespray
    echo -e "${BOLD}${YELLOW}[*]Running brutespray to brute-force services...${NC}"
    brutespray -f "${output_path}nmap_results.gnmap" -u SecLists/Usernames/top-usernames-shortlist.txt -p /usr/share/wordlists/nmap.lst -t 5 -o "$brutespray_output"

    # Check if brutespray ran successfully
    if [ $? -ne 0 ]; then
        echo -e "${BOLD}${RED}[!] Brutespray failed. Exiting...${NC}"
        exit 1
    fi

    echo -e "${BOLD}${RED}[*]Brutespray results saved to ${brutespray_output} ${NC}"
fi

