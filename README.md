[![Ansible Continuous Deployment](https://github.com/KGjidodaj/aws-project/actions/workflows/cd.yml/badge.svg)](https://github.com/KGjidodaj/aws-project/actions/workflows/cd.yml)
# AWS 3-Tier Architecture & Automated Configuration via Ansible (with mock secrets and ips)

## Overview
Infrastructure as Code (IaC) configuration for a 3-Tier web architecture deployed on AWS. All OS-level configuration, software installation and application deployment are fully automated using Ansible modular roles.

## Architecture & Network Flow
Built on strict segmentation and Zero-Trust within a custom Virtual Private Cloud (VPC):
* **Tier 1 (Public Proxy):** Nginx in a Public Subnet. The only server with a Public IP. Routes HTTP/HTTPS traffic to the internal network.
* **Tier 2 (App Layer):** Node.js API (managed by PM2) in a Private Subnet. Accepts traffic *only* from the Tier 1 Security Group.
* **Tier 3 (Database):** MySQL hosted in a Private Subnet. Network flow and data queries are explicitly managed through AWS Route Tables and Nginx proxy routing.

## Ansible Automation
* **SSH ProxyJump (Bastion Host):** Uses Tier 1 as a secure tunnel to configure the private servers (Tiers 2 & 3) without exposing them to the internet.
* **Modular Roles:** Idempotent deployment using specific roles (`nginx_proxy`, `internal_app`, `mysql_db`).
* **Ansible Vault:** Database credentials are encrypted locally and injected dynamically during execution.

## Prerequisites & Execution
1. Ensure all EC2 instances use the same `.pem` SSH keypair.
2. Copy `hosts.ini.mock` to `hosts.ini`. Input your AWS IPs and the path to your local `.pem` key.
3. Copy `group_vars/secrets.yml.mock` to `group_vars/secrets.yml`, add your password and if you want you can encrypt it: `ansible-vault encrypt group_vars/secrets.yml`.
4. Copy `ansible.cfg.mock` to `ansible.cfg`with your settings.
5. Execute the master playbook:

```bash
ansible-playbook site.yml --ask-vault-pass
```

