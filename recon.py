import requests
from sys import argv


script,domain = argv

# Send a GET request to the website
response = requests.get(f"https://crt.sh/?q={domain}&output=json")

# Check if the request was successful
if response.status_code == 200:
    # Parse the JSON content
    json_data = response.json()
    
    # Extract subdomains
    subdomains = set()
    for entry in json_data:
        name_value = entry.get('name_value')
        if name_value:
            # Split the name_value to handle multiple entries per certificate
            names = name_value.split('\n')
            for name in names:
                if name.endswith(domain):
                    subdomains.add(name)
    
    # Print the subdomains
    for subdomain in subdomains:
        print(subdomain)
else:
    print(f"Request failed with status code: {response.status_code}")
