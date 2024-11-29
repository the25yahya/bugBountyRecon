#!/bin/bash

# Check if domain_list.txt exists
if [[ ! -f domain_list.txt ]]; then
  echo "Error: domain_list.txt not found."
  exit 1
fi

# Loop through each line in domain_list.txt
while IFS= read -r domain; do
  if [[ -n $domain ]]; then  # Ensure the line is not empty
    echo "Running recon for: $domain"
    # Pass domain as $2 to recon.sh so it can set the output_path correctly
    ./recon.sh -d "$domain" -s "$domain"
  fi
done < domain_list.txt
