#!/bin/bash

# Check if a file path is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <file_path>"
  exit 1
fi

# Read the file path from the first argument
file_path=$1

# Output file to store the results
output_file="dns_results.txt"

# Clear the output file before starting
> "$output_file"

# Loop through each line in the provided file and perform a DNS query for A records
while read domain; do
  # Perform DNS A record lookup using 'dig', filter only IP addresses, and append to the output file
  dig +short A "$domain" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' >> "$output_file"
done < "$file_path"

# Notify the user that the results are saved
echo "DNS lookup results saved to $output_file"


sudo masscan -p80,443,53,3306,21,8000-8100 --banners --source-ip 192.168.1.200 -iL $output_file
