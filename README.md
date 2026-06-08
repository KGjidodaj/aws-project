# AWSec: AWS automated and secured 3-Tier Architecture (IaC & CI/CD)

[![YAML Linter](https://github.com/KGjidodaj/aws-project/actions/workflows/lint.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/lint.yml)
[![Ansible-Terraform Continuous Deployment](https://github.com/KGjidodaj/aws-project/actions/workflows/cd.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/cd.yml)

[![Terraform Version](https://img.shields.io/badge/Terraform-1.15+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Ansible Automated](https://img.shields.io/badge/Ansible-Deployed-EE0000?logo=ansible)](https://www.ansible.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<img width="957" height="396" alt="AWSec drawio" src="https://github.com/user-attachments/assets/f5e805af-ceee-4934-b6a5-e21db9ee24ba" />

## Overview
This repository deploys an Enterprise-grade AWS cloud infrastructure. It utilizes **Infrastructure as Code (IaC)**, automated **Configuration Management** and **DevSecOps** practices. The entire lifecycle is fully automated via sequential GitHub Actions. Thus ensuring secure, idempotent and observable deployments.


## Architecture & Network Topology
The underlying hardware and network are managed by **Terraform**. It constructs a 3-tier Virtual Private Cloud (VPC) implementing Network Isolation:

* **Tier 1 (Public Bastion/Proxy):** Nginx hosted in a Public Subnet with a dedicated Elastic IP. It acts as the only entry point from the public internet.
* **Tier 2 (Application Layer):** Node.js API hosted in a Private Subnet. Accepts traffic from the Tier 1 Security Group.
* **Tier 3 (Database Layer):** MySQL hosted in a Private Subnet. Accepts traffic strictly from the Tier 2 Security Group.
* **Egress Routing:** A NAT Gateway is used in the Public Subnet. It Allow outbound internet access for the Private nodes without exposing them.


## Observability & Telemetry (SaaS Monitoring)
The infrastructure is continuously monitored to prevent resource exhaustion and provide real-time metrics.

* **Grafana Alloy Agents:** Lightweight telemetry collectors deployed using Ansible across all nodes.
* **Dynamic Tagging:** Ansible inserts tags (PROXY, APP, DB) into the Alloy configuration for clean metric categorization.
* **Data Streaming:** CPU, RAM, Memory, Network I/O and systemd journal logs are securely streamed to Grafana Cloud.

<img width="1920" height="1586" alt="AWSec-grafana" src="https://github.com/user-attachments/assets/2819433e-b171-4e90-8f50-3e958a9ce1dc" />

## Configuration Management
OS configuration and application deployment are handled by **Ansible**, structured in idempotent modular roles (`grafana_agent`, `nginx`, `internal_app`, `mysql_db`).

* **Modern Package Management:** Utilizes secure `deb822_repository` format, replacing deprecated `apt-key` practices.
* **Zero-Trust SSH Tunneling:** Ansible uses an SSH `ProxyCommand` on the Nginx Bastion host to configure the private servers.
* **Secret Management:** No secrets or passwords are stored in the repo. Instead they are securely added into the runner memory during runtime via GitHub Secrets.


## CI/CD Pipeline (GitHub Actions)
The End-to-End lifecycle relies on a CI/CD pipeline architecture (`cd.yml`). It enforces Continuous Integration (CI) before initiating Continuous Deployment (CD):

* **Static Application Security Testing (SAST):** Integrates `tfsec` as a hard-fail pipeline stopper. Enforces secure HCL configurations.
* **Sequential Job Execution:** The CD phase requires the CI phase to pass (`needs: integration-checks`), preventing broken or insecure code from passing on.
* **OPSEC Log Securing:** Real-time IP extraction and masking. Prevents infrastructure leakage in action logs.
* **Automated Rollout:** Dynamic IP insertion to `group_vars/all.yml` on the runner. Followed by the execution of `ansible-playbook`.


## Local Testing & Cost Management
For any manual testing without triggering the CI/CD pipeline. This repository includes a custom interactive wrapper script (`money_saver.sh`). Executing this script will validate, format and apply the Terraform configuration. It allows ansible-playbook execution. With builtin pauses allowing the user to safely verify the deployment. Before triggering `terraform destroy` to eliminate AWS costs.
