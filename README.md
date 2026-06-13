# AWSec: AWS Automated and Secured 3-Tier Architecture (IaC & CI/CD)

[![Docker Image CI](https://github.com/KGjidodaj/aws-project/actions/workflows/docker-build.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/docker-build.yml)
[![YAML Linter](https://github.com/KGjidodaj/aws-project/actions/workflows/lint.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/lint.yml)
[![AWSec End-to-End Deployment (CI/CD)](https://github.com/KGjidodaj/aws-project/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/ci-cd.yml)

[![Terraform Version](https://img.shields.io/badge/Terraform-1.15+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Ansible Automated](https://img.shields.io/badge/Ansible-Deployed-EE0000?logo=ansible)](https://www.ansible.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-326CE5?logo=kubernetes)](https://k3s.io/)
[![Docker](https://img.shields.io/badge/Docker-GHCR-2496ED?logo=docker)](https://github.com/features/packages)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<img width="1412" height="576" alt="AWSec drawio" src="https://github.com/user-attachments/assets/8231f8a4-733d-48e3-aa5b-38343799f937" />


## Overview
This repository deploys a custom AWS cloud infrastructure. It utilizes **Infrastructure as Code (IaC)**, automated **Configuration Management**, **Container Orchestration** and **DevSecOps** practices. The entire lifecycle is automated using GitHub Actions. This ensures secure, immutable and declarative deployments.


## Architecture & Network Topology
The underlying hardware and network, managed by **Terraform**. It constructs a 3-tier VPC implementing Micro-segmentation:

* **Tier 1 (Public Bastion/Proxy):** Nginx hosted in a Public Subnet with an Elastic IP. It acts as the DMZ and sole entry point. It utilizes L7 Split-Routing, serving a custom landing page. This mitigates passive nginx scanning, while at the same time nginx is securely proxying API traffic (/api/) internally.
* **Tier 2 (Application Layer / K8s):** A single-node **Kubernetes (K3s)** cluster hosted in a Private Subnet. It runs the containerized Node.js application in Pod replicas. It accepts traffic only from the Tier 1 Security Group via Kubernetes NodePort (`30000`).
* **Tier 3 (Database Layer):** MySQL hosted in a Private Subnet. Accepts traffic strictly from the Tier 2 K8s network.
* **Egress Routing:** A NAT Gateway is used in the Public Subnet. It allows outbound internet access for the Private nodes without exposing them.
* **Traffic Blackholing:** The Nginx configuration uses a strict SNI-only policy. A 'catch-all' block drops connections targeted at the Public IP. This renders the server invisible to automated botnets and unauthorized port scanners.


## Cryptography & Public Key Infrastructure (PKI)

##  Cryptography & Identity (A+ SSL Rating)
All external communications are encrypted using Let's Encrypt certificates, managed using Ansible and Certbot.
* **A+ SSLLabs Rating:** The proxy strictly enforces TLS 1.2 and TLS 1.3, utilizing Mozilla's Intermediate cipher suites.
* **Perfect Forward Secrecy (PFS):** Session tickets are disabled to ensure that past communications cannot be decrypted even if the private key is compromised.
* **HSTS Enforced:** Strict-Transport-Security headers guarantee that browsers only interact with the infrastructure over HTTPS.


## Observability & Telemetry (SaaS Monitoring)
The infrastructure can be continuously monitored. Preventing resource exhaustion while also providing metrics.

* **Grafana Alloy Agents:** Lightweight agents deployed using Ansible across all nodes. For telemetry purposes.
* **Dynamic Tagging:** Ansible inserts tags (e.g DB) into the Alloy configuration for clean metric categorization.
* **Data Streaming:** CPU, RAM, Memory, Network I/O and systemd journal logs are streamed to Grafana.

<img width="1920" height="1586" alt="AWSec-grafana" src="https://github.com/user-attachments/assets/2819433e-b171-4e90-8f50-3e958a9ce1dc" />


## Configuration Management & Orchestration
OS configuration, K3s bootstrapping and cluster deployments, handled by **Ansible**. Structured in idempotent modular roles:
(`grafana_agent`, `nginx`, `internal_app`, `mysql_db`)

* **Declarative K8s Manifests:** Replaces legacy imperative deployments. Ansible dynamically templates Kubernetes YAML files (`app-manifests.yml`).
* **Dynamic State Injection:** No secrets are stored in the repo. Ansible extracts Terraform state (Private IPs) and Vault credentials. Then inserts them directly into the Kubernetes Pod Environment Variables during runtime.
* **Zero-Trust SSH Tunneling:** Ansible utilizes an SSH `ProxyCommand` via the Nginx Bastion host to securely configure the private servers.
## Dynamic Edge Security & Intrusion Prevention (IPS)
The public-facing Bastion host is fortified against Layer 7 volumetric and targeted attacks.
* **Traffic Shaping:** Nginx employs Token-Bucket rate limiting (`limit_req_zone`) handling sudden traffic spikes without delaying legitimate requests.
* **Dynamic IPS (CrowdSec):** A locally deployed CrowdSec agent parses access and authentication logs. Paired with an Nginx Bouncer that actively drops connections from malicious IPs. Together they effectively shield the internal Kubernetes overlay network from unauthorized scans and brute-force attempts.

##  Idempotency & Templating
The Configuration adheres to strict idempotency standards. Execution workflows are engineered to evaluate the target state before applying changes. This ensures playbooks can run continuously without changing already configured infrastructure. Furthermore, hardcoded values have been entirely eliminated and are inserted dynamically at runtime using secure Jinja2 templating.


## CI/CD Pipelines (GitHub Actions)
The End-to-End lifecycle relies on two distinct pipelines separating concerns:

1. **Docker Build Pipeline (`docker-build.yml`):** Automatically triggers on application code changes. It builds the Alpine-based Dockerfile. Pushes the image to the GitHub Container Registry (GHCR).
2. **Infrastructure Pipeline (`ci-cd.yml`):** Enforces Continuous Integration (CI). Then it initiates Continuous Deployment (CD).
   * **Static Application Security Testing (SAST):** Integrates `tfsec` as a hard-fail pipeline stopper. Enforcing secure HCL configurations.
   * **Sequential Job Execution:** The CD phase requires the CI phase to pass. Thus preventing broken or insecure code from reaching production.
   * **OPSEC Log Securing:** Live action IP extraction and masking prevent infrastructure leakage.


## Local Testing & Cost Management
For manual testing without triggering the pipelines. This repository includes a custom interactive wrapper script (`money_saver.sh`). Executing this script validates, formats and applies the Terraform configuration, followed by the `ansible-playbook` execution. It features built-in pauses allowing the user to safely verify the deployment. Afterward, it automatically triggers `terraform destroy` to eliminate AWS costs. User only needs to: First create the inventory/group_vars/all.yml file. Second insert all secrets needed. Then allow the script to run the ansible-playbook command.
