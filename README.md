# Vault long-cert-formatter

This is a simple script to format a certificate in a long format. It is useful for formatting the certificates that are generated via vault commands similar to these:

## Note

Run this in case you found \r failures on running the script

```sh
 sed -i 's/\r$//' format_cert.sh
```

## Generate certificate

Create Role:

```sh
curl -s -v -X POST --insecure https://vault.us-east-1.aws.generic-cloud:8200/v1/pki_int/roles/vault-test -H "X-Vault-Token:<vault-token>" -d '{"allow_any_name": "true", "allow_subdomains": "true", "max_ttl": "26000h", "ttl": "26000h"}'
```

Create Certificate:

```sh
curl -s -v -X POST --insecure https://cc-smb-vault.us-east-1.aws.generic-cloud:8200/v1/pki_int/issues/vault-test -H "X-Vault-Token:<vault-token>" -d '{"allow_any_name": "true", "allow_subdomains": "true", "max_ttl": "26000h", "ttl": "26000h", "common_name": "us-east-1.aws.generic-cloud"}`
```

The second command will generate a blob of text that contains the certificate, the private key, and the CA certificate. Save that blob of text into a text file and run this script on it. It will output the certificate in the format required in order to access Smarsh apis.

## Requirements

- bash installed
- openSSL installed
- awk installed

## Usage

### On macOS

```bash

./format_cert.sh <vault_url> <directory_structure> <role_name> <vault_token> <common_name> <ttl_hours>

```

Example:

```bash

./format_cert.sh prod-vault.us-west-2.aws.generic-cloud dev/pki_int vault-test s.123456784744b *.us-east-1.generic-cloud.com 26000h
```

### With Docker

Make sure the vault grab is saved as vault_cert.txt and run the following command:

```sh
docker build -t cert-formatter .
```

You will receive the following output:

- actor-cert.pem
- key.pem
- new-cert.pem
- `<name-specified>.p12`
- `<name-specified>.pfx`

