# AWSec: Automated and Secured 3-Tier Architecture (IaC & CI/CD)

[![AWSec End-to-End Deployment (CI/CD)](https://github.com/KGjidodaj/aws-project/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/ci-cd.yml)
[![Docker Image CI](https://github.com/KGjidodaj/aws-project/actions/workflows/docker-build.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/docker-build.yml)
[![YAML Linter](https://github.com/KGjidodaj/aws-project/actions/workflows/yaml-lint.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/yaml-lint.yml)
[![Gitleaks Scan](https://github.com/KGjidodaj/aws-project/actions/workflows/gitleaks.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/gitleaks.yml)
[![Ansible Lint](https://github.com/KGjidodaj/aws-project/actions/workflows/ansible-lint.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/ansible-lint.yml)
[![Dependabot](https://badgen.net/github/dependabot/KGjidodaj/aws-project)](https://github.com/KGjidodaj/aws-project/network/updates)
[![Terraform Version](https://img.shields.io/badge/Terraform-1.15+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Ansible Automated](https://img.shields.io/badge/Ansible-Deployed-EE0000?logo=ansible)](https://www.ansible.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-326CE5?logo=kubernetes)](https://k3s.io/)
[![Docker](https://img.shields.io/badge/Docker-GHCR-2496ED?logo=docker)](https://github.com/features/packages)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<img width="1412" height="576" alt="AWSec drawio" src="https://github.com/user-attachments/assets/8231f8a4-733d-48e3-aa5b-38343799f937" />

## Overview
This repository deploys a custom AWS cloud infrastructure. It is built strictly on **Infrastructure as Code (IaC)**, automated **Configuration Management**, **Container Orchestration** and **DevSecOps** practices. The entire lifecycle is automated using GitHub Actions ensuring secure, immutable and declarative deployments.


##  Architecture & Network Topology
The hardware and network are provisioned using **Terraform**, constructing a safe 3-tier VPC:

* **Tier 1 (Public Bastion/Proxy):** An Nginx server hosted in a Public Subnet with an Elastic IP. It acts as the only entry point. It utilizes L7 Split-Routing to serve a landing page while securely proxying API traffic (`/api/`) internally.
* **Tier 2 (Application Layer / K8s):** A single-node **Kubernetes (K3s)** cluster hosted in a Private Subnet. It runs the containerized Node.js application in Pod replicas. It also accepts traffic only from the Tier 1 Security Group via NodePort (`30000`).
* **Tier 3 (Database Layer):** MySQL hosted in an isolated Private Subnet, accepting traffic strictly from the Tier 2 K8s network.
* **Egress Routing:** A NAT Gateway in the Public Subnet grants outbound internet access to the private nodes without exposing them.


##  Security & Hardening (Defense in Depth)
The infrastructure implements a multi-layered security approach while  neutralizing threats.

* **Cryptography (A+ SSLLabs Rating):** All traffic is encrypted using Let's Encrypt certificates (automated with Ansible). The proxy enforces TLS 1.2/1.3, Mozilla's Intermediate cipher suites and HSTS preloading. Forward Secrecy is guaranteed by disabling session tickets.
* **Traffic Blackholing (Stealth Mode):** Nginx strictly enforces an SNI-only policy. A 'black hole' block drops (`HTTP 444`) direct IP connections. This renders the server invisible to botnets. Additionally, `server_tokens` are disabled to prevent OS/version leakage.
* **Dynamic IPS & Rate Limiting:** Nginx employs Token-Bucket rate limiting absorbing DDoS spikes. At the same time, a CrowdSec agent parses access logs actively dropping connections from malicious IPs using an Nginx Bouncer.
* **Container Privilege De-escalation:** The Node.js application executes under an unprivileged user (`appuser`). Root access is explicitly dropped within the Dockerfile to mitigate Container Escape risks.
* **API Route Hardening:** The Express.js backend implements strict Catch-All routing  returning standardized JSON 404 responses rather than leaking system information on undefined endpoints.


##  Configuration Management & Idempotency
OS configuration, K3s bootstrapping and cluster deployments are orchestrated using **Ansible** highly modular roles (`grafana_agent`, `nginx`, `internal_app`, `mysql_db`).

* **Strict Idempotency:** Execution workflows ensure clean pushes before applying changes, making sure playbooks run without altering existing infrastructure.
* **Declarative Deployments:** Used Ansible to dynamically template Kubernetes YAML manifests and for role deployment.
* **Dynamic State Injection:** No secrets exist in the repo. Ansible securely extracts IPs (from terraform) and Vault credentials. Then inserts them into K8s Pod variables and configurations using Jinja2 templating.
* **Zero-Trust Provisioning:** Ansible utilizes an SSH key `ProxyCommand` via the Nginx Bastion host to configure the private servers securely.


## CI/CD Pipelines & Automation
The End-to-End lifecycle is orchestrated using GitHub Actions workflows. The architecture strictly enforces a separation of concerns:

1. **Linting & Configuration Quality (`lint.yml`):** Triggers on all Pull Requests and commits. 
   * **Ansible-Lint:** Evaluates playbook structures. Enforces idempotency rules and declarative module usage.
   * **Yamllint:** Scans Kubernetes manifests and workflows to enforce syntax correctness and strict indentation.

2. **Secret Scanning & OPSEC (`gitleaks.yml`):** * Integrates **Gitleaks** to perform deep Git scans on every push. It acts as a hard-fail, preventing secrets from being exposed.

3. **Dependency-Update Security (Dependabot):**
   * Continuously monitors the `Dockerfile` for outdated base images, the Terraform configuration for deprecated AWS providers and GitHub Actions for vulnerable runner versions.

4. **Docker Build Pipeline (`docker-build.yml`):** * Automatically triggers on application code changes. It builds the Alpine-based Node.js container image and pushes it to the GHCR.

5. **Infrastructure Deployment Pipeline (`ci-cd.yml`):** Enforces CI/CD separation for the cloud environment.
   * **Shift-Left SAST:** Integrates `tfsec` as a hard-fail mechanism, preventing insecure Terraform configurations (e.g., exposed Security Groups) from advancing.
   * **Sequential Execution:** The CD phase (Terraform Apply / Ansible Provisioning) executes only if the CI phase passes.
   * **Log Masking:** Live IP extraction and masking are used to prevent infrastructure configuration and routing structures leaks.


##  Observability & Telemetry
The infrastructure is monitored to prevent resource exhaustion and provide detailed insights.

* **Grafana Alloy Agents:** Lightweight agents deployed via Ansible across all nodes for telemetry data collection.
* **Dynamic Tagging:** Ansible inserts tags (e.g., `role: db`) into the Alloy configuration for metric categorization.
* **Data Streaming:** Live CPU, RAM, Network I/O and `systemd` journal logs are streamed to Grafana Cloud.


<img width="1920" height="1586" alt="AWSec-grafana" src="https://github.com/user-attachments/assets/2819433e-b171-4e90-8f50-3e958a9ce1dc" />


##  Local Testing & FinOps (Cost Management)
For manual testing without triggering pipelines. This repository includes a custom interactive wrapper (`money_saver.sh`). Executing this script validates and applies Terraform configurations, followed by `ansible-playbook` execution. It features built-in pauses for deployment verification. Then it automatically triggers `terraform destroy` to eliminate idle AWS costs.
*Usage:* Only things needed by the user:
1) Import ssh key to the ansible directory `./aws_homelab.pem`.
2) Create vault password key in the ansible directory `./.vault_pass`
3) Open and configure the .env file to your liking.
