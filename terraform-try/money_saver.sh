#!/usr/bin/env bash
#Colours for results
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color for the resets

echo "Running terraform validate to check the code, might take a little time..."
terraform validate

echo  "Would you like to check the plan-reorganize the code(terraform plan&terraform fmt) "
read -p "[Yes/No]: " answer
if [[ $answer == "yes" ]] || [[ $answer == "Yes" ]]; then
    echo "Running the commands..."

    echo "Running terraform fmt..."
    terraform fmt

    echo -e "Running terraform plan... \n(sleeping for 6 seconds at the end for a double check)"
    terraform plan
    sleep 6

fi

echo "Running terraform apply to apply any changes, might take a little time..."
if terraform apply; then
    echo -e "\n\n\n${GREEN}Terraform apply worked.--------------------${NC}"
    read -p "Pausing the script before destruction, do whatever you need and then press enter."

    echo "Starting the teardown process with terraform destroy--------------."
    sleep 0.5
    if terraform destroy; then
        echo -e "${GREEN}[+] Destroy command finished, billing stopped.${NC}"
    else
        echo -e "${RED}[!] ERROR: Command stopped get now into the aws cloud account and disable manually to stop billing!${NC}"
        exit 1
    fi
 else
    echo -e "${RED}[!] ERROR: Terraform apply stopped re run the script and if needed stop the billings via the aws cloud account.${NC}"
    exit 1
fi

