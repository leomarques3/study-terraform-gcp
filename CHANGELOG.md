# study-terraform-gcp - Changelog

## **[1.0.2]**

### 2021-09-24
#### **_Added_:**
- Added Makefile to execute shell scripts
- Added shell script `create.sh` to execute all terraform commands
- Added MySQL database into terraform scripts

## **[1.0.1]**

### 2021-09-21
#### **_Changed_:**
- Changed cluster to be private
- Created a bastion host to access the cluster through ssh
- Added new firewall rule
- Created new service account for the bastion host
- Removed Makefile and shell scripts

## **[1.0.0]**

### 2021-09-17
#### **_Added_:**
- Terraform scripts for GCP
  - Creation of VPC
  - Creation of Subnetworks
  - Creation of Firewall rules
  - Creation of Cloud Router and Cloud NAT
  - Enabling of services
  - Creation of Artifact Registry repository
  - Creation of a Service Account with necessary roles
  - Creation Cluster with Nodes and Node Pool
- Makefile scripts
- Shell scripts to execute terraform
- GitHub Actions CI