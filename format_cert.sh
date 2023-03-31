#!/bin/bash

# This script is used to format the long TTL certificate for use with SRE tools. 

#  **JUST NEED THE 2ND AND THIRD CERT WITH PRIVATE KEY FOR THE LONG TTL**


export VAULT_SKIP_VERIFY="true"

vault_url=$1
pki_backend=$2
vault_role=$3
vault_token=$4
common_name=$5
ttl_hours=$6

# help section for the input variables
if [ "$1" == "-h" ]; then
    echo "Usage: $0 <vault_url> <pki_backend> <role_name> <vault_token> <common_name>"
    echo "Example: $0 vault.us-east-1.generic-cloud.com dev/pki_int vault-test t.123456784744b *.us-east-1.generic-cloud.com"
    exit 0
fi

# validation for the input variables
if [ -z "$1" ]; then
    echo "Please provide the vault url, ie vault.us-east-1.generic-cloud.com"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Please provide the pki backend structure, ie test/pki_int, pki_int, pki, etc."
    exit 1
fi

if [ -z "$3" ]; then
    echo "Please provide the role name, ie vault-test"
    exit 1
fi

if [ -z "$4" ]; then
    echo "Please provide the vault token"
    exit 1
fi

if [ -z "$5" ]; then
    echo "Please provide the common name, ie *.us-east-1.generic-cloud.com"
    exit 1
fi

if [ -z "$6" ]; then
    echo "Please provide the ttl hours, ie 43700h for 5 years 26000h for 3 years"
    exit 1
fi


# Until we are 100% sure on how the pki part of the string is constructed for each environment 
# we will need to update this part each time - /env/pki_int/ . For prod this is generally 
# /pki/ but we need to verify this.

# Create Role
echo "Creating role $vault_role"
curl -s -v -X POST --insecure https://$vault_url:8200/v1/$pki_backend/roles/$vault_role -H "X-Vault-Token: $vault_token" -d '{"allow_any_name": "true", "allow_subdomains": "true", "max_ttl": "26000h", "ttl": "26000h"}'

echo "Generating certificate for $common_name"
# Generate Certificate
curl -s -v -X POST --insecure https://$vault_url:8200/v1/$pki_backend/issue/$vault_role -H "X-Vault-Token: $vault_token" -d '{"allow_any_name": "true", "allow_subdomains": "true", "max_ttl": "26000h", "ttl": "26000h", "common_name": "*.us-east-1.generic-cloud.com"}' > output.txt


# Check if the output.txt file exists

if [ -f output.txt ]; then
    # Check if the file is empty
    if [ -s output.txt ]; then

        # Replace every \n with a new line
        awk '{gsub(/\\n/,"\n")}1' output.txt  > newfile.txt
        # split -----END CERTIFICATE----- and -----BEGIN CERTIFICATE----- 
        awk '{gsub(/-----END CERTIFICATE-----/,"-----END CERTIFICATE-----\n")}1' newfile.txt > newfile1.txt
        # on same line remove any preceeding text before -----BEGIN CERTIFICATE-----
        awk '{gsub(/.*-----BEGIN CERTIFICATE-----/,"-----BEGIN CERTIFICATE-----")}1' newfile1.txt > newfile2.txt
        #  on the same line remove any preceeding text before -----BEGIN RSA PRIVATE KEY-----
        awk '{gsub(/.*-----BEGIN RSA PRIVATE KEY-----/,"-----BEGIN RSA PRIVATE KEY-----")}1' newfile2.txt > newfile3.txt
        # on the same line remove any text after the END RSA PRIVATE KEY-----
        awk '{gsub(/.*-----END RSA PRIVATE KEY-----.*/,"-----END RSA PRIVATE KEY-----")}1' newfile3.txt > newfile4.txt


        # count all certicates between -----BEGIN CERTIFICATE----- and -----END CERTIFICATE----- and save to variable
        certcount=$(grep -e "-----BEGIN CERTIFICATE-----*" newfile4.txt | wc -l)
        echo "There are $certcount certificates in the file"

        #  find what line the first occurrence of -----END CERTIFICATE----- is on and save to variable
        firstline=$(awk '/-----END CERTIFICATE-----/ { print NR; exit}' "newfile4.txt")
        echo "The first certificate ends on line $firstline"

        #  delete all lines in file until $firstline using awk
        awk 'NR > '$firstline'' newfile4.txt > new-cert.pem

        # get the linenumber of the first occurrence of -----END CERTIFICATE----- and save to variable
        secondline=$(awk '/-----END CERTIFICATE-----/ { print NR; exit}' "new-cert.pem")

        #  create new cert1.pem file with the first certificate
        awk 'NR < '$(($secondline + 1))'' new-cert.pem > actor-cert.pem
        
        
        rm newfile.txt
        rm newfile1.txt
        rm newfile2.txt
        rm newfile3.txt
        rm newfile4.txt

        # get openssl enddate of the certificate
        enddate=$(openssl x509 -enddate -noout -in new-cert.pem | awk -F= '{print $2}')
        echo "Certificate file created with end date of $enddate"

        # get private key from certificate file and save to key.pem
        awk '/-----BEGIN RSA PRIVATE KEY-----/,/-----END RSA PRIVATE KEY-----/' new-cert.pem > key.pem

        #  get certificate from certificate file and save to cert.pem
        awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' new-cert.pem > certs-only.pem


        # export to java keystore
        openssl pkcs12 -export -in cert.pem -inkey key.pem -out $output_file.p12 -password pass:superuser
        # create pfx key
        openssl pkcs12 -inkey key.pem -in cert.pem -export -out $output_file.pfx -password pass:superuser


    else
        echo "The file is empty"
    fi
else
    echo "The file does not exist"
fi

# End of script
