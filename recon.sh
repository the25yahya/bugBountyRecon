#! /bin/bash
BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

domain=""
directory=""

source "$(dirname "$0")/scan.sh"



while getopts ":d:ljs" opt; do 
    case $opt in
        d)
            domain=$OPTARG
            directory="${domain}_recon"
            ;;
        l)
            linked_discovery_flag=true
            ;;
        s)
            scraping_flag=true
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
(
    cd "$output_path" || exit
    touch subdomains.txt actual_sites.txt site_urls.txt interesting.txt

)

#function calls

if [ "$linked_discovery_flag" = true ]; then
    linked_discovery "$domain" "$directory"
fi

if [ "$scraping_flag" = true ]; then
    scraping "$domain" "$directory"
fi