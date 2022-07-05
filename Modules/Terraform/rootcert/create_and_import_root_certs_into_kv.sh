#!/bin/bash

export subscription_id=$1
export #client_id=$2
export #client_secret=$3
export tenant_id=$4
export root_cert_name=$5
export keyvault_name=$6
export root_cert_passphrase=$7
export root_cert_policy=$8

# SUBJECT="/C=US/O=ATT/OU=DICA/CN=${root_cert_name}"

set -e # errors matter

az login --service-principal --username ${client_id} --password ${client_secret} --tenant ${tenant_id}

key_vault_uri=$(az keyvault show --name "$keyvault_name" --subscription "$subscription_id" --query 'properties.vaultUri' -o tsv)

# create self-signed certificate to use as Root CA
echo "creating Root CA certificate using the following policy:"
cat $root_cert_policy

## using 'rest' command because 'az keyvault certificate create' does not support a policy that allows resulting certificate to be used as Root CA
## see: https://docs.microsoft.com/en-us/rest/api/keyvault/createcertificate/createcertificate
az rest --method post --uri "$key_vault_uri"certificates/"$root_cert_name"/create?api-version=7.0 --body @$root_cert_policy --resource https://vault.azure.net

# wait until root certificate becomes available
root_cert_status=
while [ "$root_cert_status" != "true" ]; do
  echo "Checking status of Root Certificate..."
  root_cert_status=$(az keyvault certificate show --name $root_cert_name --vault-name "$keyvault_name" --query 'attributes.enabled' -o tsv)
  [ "$root_cert_status" != "true" ] && sleep 10
done
echo "Root Certificate has been enabled"