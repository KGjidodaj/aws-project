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
    sleep 6 #allowing the user to quickly read the plans

fi

echo "Running terraform apply to apply any changes, might take a little time..."
if terraform apply; then
    echo -e "\n\n\n${GREEN}Terraform apply worked.--------------------${NC}"
    read -p "Would you like to continue with Ansible deployment before destruction(yes/no):" ansible

    if [[ $ansible == "Yes" ]] || [[ $ansible == "yes" ]];then

        # Outputting the raw ips and saving in the all.yml file like in the pipeline for dynamic IP usage.
        echo "Extracting IPs for local ansible-playbook usage"
        NGINX_IP=$(terraform output -raw nginx_public_ip)
        APP_IP=$(terraform output -raw app_private_ip)
        DB_IP=$(terraform output -raw mysql_private_ip)

        mkdir -p ../inventory/group_vars > /dev/null 2>&1

        if [[ -f  ../inventory/group_vars/all.yml ]];then
                echo " "
        else
                echo "[*] Injecting IPs into Ansible configuration..."
                cat <<EOF > ../inventory/group_vars/all.yml
nginx_ip: "${NGINX_IP}"
app_ip: "${APP_IP}"
db_private_ip: "${DB_IP}"
key_location: "./aws-homelab.pem"
db_root_password: "local_testing_password"
db_name: "db_name"
db_user: "homelab_user"
ansible_ssh_private_key_file: "./aws-homelab.pem"
grafana_token: "input your token here for the grafana alloy agents"
EOF

                echo "Add your your own secrets to this file!!!"
                sleep 4
        fi

        cd ..
        echo "Running ansible-playbook..."
        ansible-playbook site.yml
        cd Terraform
    fi

    read -p "Pausing the script before destruction, when you want to continue!"
    echo "Starting the teardown process with terraform destroy----------."
    sleep 0.5

    if terraform destroy; then
        echo "Starting the teardown process with terraform destroy--------------."
        sleep 0.5
        echo -e "${GREEN}[+] Destroy command finished, billing stopped.${NC}"
    else
        echo -e "${RED}[!] ERROR: Command stopped get now into the aws cloud account and disable manually to stop billing!${NC}"
        exit 1
    fi

else
    echo -e "${RED}[!] ERROR: Terraform apply stopped re run the script and if needed stop the billings via the aws cloud account.${NC}"
    exit 1
fi

