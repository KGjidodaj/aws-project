[![Ansible-Terraform Continuous Deployment](https://github.com/KGjidodaj/aws-project/actions/workflows/cd.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/cd.yml)

# Enterprise AWS 3-Tier Architecture (IaC & CI/CD)

## Overview
This repository deploys and configures an AWS cloud infrastructure utilizing **Infrastructure as Code (IaC)** and automated **Configuration Management**. The entire lifecycle is fully automated via GitHub Actions, leaving no static IPs or hardcoded secrets in the repository.

## Architecture & Network Topology
The underlying hardware and L3/L4 network are managed by **Terraform**. It constructs a 3-tier Virtual Private Cloud (VPC) implementing Network Isolation:

* **Tier 1 (Public Bastion/Proxy):** Nginx hosted in a Public Subnet with a dedicated Elastic IP. It acts as the ingress controller and the only entry point from the public internet.
* **Tier 2 (Application Layer):** Node.js API hosted in a **Private Subnet**. Accepts traffic strictly from the Tier 1 Security Group.
* **Tier 3 (Database Layer):** MySQL hosted in a **Private Subnet**. Accepts traffic strictly from the Tier 1 Security Group.
* **Egress Routing:** A **NAT Gateway** is deployed in the Public Subnet to allow outbound internet access for the Private nodes without exposing them to inbound threats.

## Configuration Management & Deployment
Operating system configuration and application deployment are handled by **Ansible**. Structured in idempotent modular roles (`nginx_proxy`, `internal_app`, `mysql_db`).

* **Dynamic Temporary Inventory:** IP addresses are extracted dynamically from Terraform state during the CI/CD run.
* **Zero-Trust SSH Tunneling:** Ansible utilizes an SSH `ProxyCommand` to jump through the Nginx Bastion host to configure the private servers. Ensuring the DB and App layers are never exposed.
* **Secret Management:** No secrets or vault passwords are stored in the repository. Database passwords and SSH keys are securely added into the runner memory during runtime via GitHub Secrets.

## CI/CD Pipeline (GitHub Actions)
The End-to-End lifecycle relies on a unified pipeline architecture (`cd.yml`). It enforces Continuous Integration (CI) gates before initiating Continuous Deployment (CD):

1. **CI / Quality Gates:** Triggers syntax checks, Ansible linting, and Terraform validation.
2. **Deployment Blocker (`needs` directive):** The CD phase is strictly blocked and will abort if any CI quality gate fails, preventing broken code from reaching the infrastructure.
3. **AWS Authentication:** Secure login using IAM keys.
4. **Infrastructure Deployment:** `terraform apply` builds the cloud infrastructure and utilizes a remote AWS S3 Backend for State management.
5. **OPSEC Log Securing:** Real-time IP extraction and masking (`::add-mask::`). Preventing infrastructure leakage in public action logs.
6. **Configuration Delivery:** Dynamic IP insertion to `group_vars/all.yml` on the runner. Followed by the execution of `ansible-playbook`.
7. 
## Local Testing & Cost Management
For manual testing without triggering the CI/CD pipeline, this repository includes a custom interactive wrapper script (`money_saver.sh`). Executing this script will automatically validate, format and apply the Terraform configuration. It then pauses execution allowing the user to manually trigger the Ansible deployment. Then safely destroying all resources (`terraform destroy`) to ensure reduced AWS costs.

## Reproducibility
*Note: This is an automated CI/CD repository. Manual execution may cause errors.*
To replicate this environment in your own AWS account:
1. Configure AWS IAM credentials and an SSH Key pair.
2. Create an S3 Bucket and update the Terraform backend according to your configuration in `terraform-try/terraform.tf`.
3. Add the required Repository Secrets to GitHub (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SSH_KEY`, `DB_PASSWORD`) or any extra if it is needed.
4. Push to the `main` branch to trigger the workflow.
5. To prevent unnecessary AWS charges after testing(if aws and terraform are configured in the terminal). You can securely tear down the infrastructure locally by navigating to the terraform directory and running: `terraform init && terraform destroy`
