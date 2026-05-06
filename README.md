# TechCorp Terraform Infrastructure - Month 1 Assessment
### AltSchool Cloud Engineering - Karatu 2025

## Project Overview
This repository contains a complete Terraform configuration for TechCorp's new multi-tier web application. The infrastructure is designed for high availability, security, and scalability, featuring a public-facing load balancer and isolated private tiers for web and database services.

## Architecture Highlights
* **VPC:** Custom VPC (`10.0.0.0/16`) named `techcorp-vpc` with DNS hostnames enabled.
* **High Availability:** Resources are distributed across two Availability Zones (`us-east-1a` and `us-east-1b`).
* **Network Isolation:** * **Public Subnets:** Host the Application Load Balancer and Bastion Host.
    * **Private Subnets:** Host the Web Servers and PostgreSQL Database, protected from direct internet access.
* **Security Groups:** Tiered access control allowing HTTP/S only to the ALB, and SSH only through the Bastion Host.

## Prerequisites
* Terraform (v1.0+)
* AWS CLI configured with appropriate credentials.
* An existing AWS Key Pair (Default name: `techcorp-key`).

## Deployment Instructions
1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Configure Variables:**
    Review `variables.tf` or create a `terraform.tfvars` file to specify your `my_ip` (for Bastion access) and `key_name`.
3.  **Deploy Infrastructure:**
    ```bash
    terraform apply --auto-approve
    ```

## Administrative Access & Verification
* **Bastion Access:** The Bastion host is configured for password authentication. 
    * **User:** `ec2-user`
* **Web Access:** Use the `alb_dns_name` provided in the Terraform outputs to view the web application served by the private instances.
* **Database Access:** Connect to the PostgreSQL instance (`port 5432`) only via the Bastion or Web servers.

## Infrastructure Cleanup
To prevent unnecessary AWS costs, destroy all resources when the assessment review is complete:
```bash
terraform destroy --auto-approve