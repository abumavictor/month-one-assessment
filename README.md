# TechCorp Infrastructure Deployment (Month One Assessment)

## Project Overview
This repository contains the Terraform configuration files used to deploy a highly available and secure infrastructure for TechCorp on AWS.

## Architecture Components
* **VPC:** Custom VPC with 2 public and 2 private subnets across multiple Availability Zones.
* **Compute:** Web servers in public subnets and a Database server in a private subnet.
* **Security:** Security groups restricting access to port 80 (HTTP) and 22 (SSH).
* **Automation:** User data scripts for automatic installation of Apache and MariaDB.

## Files
* `main.tf`: Core resource definitions.
* `variables.tf`: Input variables for flexibility.
* `outputs.tf`: Key information like Load Balancer DNS.
* `user_data/`: Bash scripts for server configuration.

## Author
**Abuma Victor Ibrahim** Cloud Engineering Student @ AltSchool Africa
