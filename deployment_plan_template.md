# MOSIP deployment

> **Reference Documentation**: This deployment guide provides step-by-step instructions for deploying MOSIP. For comprehensive information about hardware requirements, network architecture, certificate requirements, and other prerequisites, please refer to the official MOSIP documentation at [https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites](https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites). The official documentation contains detailed specifications for VM sizing, network requirements, DNS configuration, and certificate management that should be reviewed before beginning deployment.

## Introduction

This document is the working deployment plan for installing MOSIP 1.2.0.2 with the Turing automation framework. Copy this template to `deployment_plan.md`, replace the **REFERENCE** values with your environment details, and use it as the shared checklist for the teams responsible for DNS, certificates, networking, virtual machines, and the MOSIP deployment itself.

The repository is an automation framework for the MOSIP deployment process. It uses the same MOSIP Helm charts and chart repositories as the official MOSIP deployment flow. It does not modify MOSIP application code, patch MOSIP modules, or replace MOSIP's own chart logic. The purpose of this framework is to make the official deployment process more repeatable, easier to verify, and easier to re-run when a step needs to be repeated.

At a high level, the deployment flow is: prepare prerequisites, optionally provision AWS base infrastructure, deploy WireGuard access, deploy the observation node, deploy the MOSIP infrastructure layer, and then deploy the MOSIP application modules.

## Deployment architecture overview

All deployment commands should be run from a **deployment node**. This is a separate Ubuntu 22.04 machine used as the operator workstation for Ansible, Terraform, Helm, `kubectl`, certificate handling, and inventory management. The deployment node is not a MOSIP application node; it is the control point used to install and manage the environment.

The target environment contains the WireGuard bastion, MOSIP Nginx reverse proxy, observation node, and MOSIP Kubernetes nodes. The deployment node must be able to SSH to these machines and reach the Kubernetes API endpoints created during the deployment.

Where possible, place the deployment node on the same private network as the MOSIP and observation nodes. Ansible copies scripts and configuration to several machines, and Terraform/Helm repeatedly communicate with the Kubernetes cluster while waiting for modules to become healthy. Running those operations across a high-latency path, a VPN-only path, or an unreliable route increases the chance of slow deployments, SSH interruptions, chart download failures, and Kubernetes API timeouts.

You may keep the deployment node powered off after installation and use it again for day-two operations such as changing Terraform variables, re-running Ansible, or applying upgrades.

## Prerequisites

After cloning the repository, copy this `deployment_plan_template.md` into `deployment_plan.md` and update all **REFERENCE** values.

This deployment guide is platform-agnostic and can be used with any hypervisor or cloud provider (OpenStack, VMware, AWS, Azure, bare metal, etc.) as long as the following prerequisites are met. The Ansible playbooks will deploy to any Linux-based VMs that meet the requirements, and Terraform handles Helm and Kubernetes.

### Deployment Paths

Use one flow with two infrastructure entry paths:

- [AWS](#aws-provisioning): run AWS Terraform base infrastructure provisioning first, then continue the same Ansible and Terraform stages below. Except for the deployment node provisioning, the prerequisites section is automatically created on AWS.
- On-prem: use your existing VM provisioning path and continue the standard Ansible/Terraform stages below. You manually create all resources listed in the prerequisites section before you start the deployment.

### Domain Configuration

Before starting, you need to define your MOSIP domain. Replace `{MOSIP_DOMAIN}` throughout this document with your actual domain (e.g., `mosip.example.com` or `sandbox.example.org`). Subdomains are allowed, e.g. for multiple MOSIP environments under the same top-level domain. E.g. prod.mosip.net, dev.mosip.net

### DNS Records

Note: For AWS deployment, there is an option to automatically configure all DNS records. [See AWS section](#aws-provisioning)
Configure the following DNS records for your `{MOSIP_DOMAIN}`. Replace `{MOSIP_DOMAIN}` with your actual domain and update IP addresses to match your infrastructure:


| **Record Type** | **Domain Name**             | **IP/DNS**                  | **Mapping details**                                                 | **Purpose**                                                                                                                                                                                                                                       |
| --------------- | --------------------------- | --------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A Record        | rancher.{MOSIP_DOMAIN}      | `<OBS_NGINX_PRIVATE_IP>`    | Private IP of Nginx server or load balancer for Observation cluster | Rancher dashboard to monitor and manage the Kubernetes cluster.                                                                                                                                                                                   |
| A Record        | keycloak.{MOSIP_DOMAIN}     | `<OBS_NGINX_PRIVATE_IP>`    | Private IP of Nginx server for Observation cluster                  | Administrative IAM tool (keycloak). This is for the Kubernetes administration.                                                                                                                                                                    |
| A Record        | api-internal.{MOSIP_DOMAIN} | `<MOSIP_NGINX_PRIVATE_IP>`  | Private IP of Nginx server for MOSIP cluster                        | Internal API's are exposed through this domain. They are accessible privately over wireguard channel                                                                                                                                              |
| A Record        | api.{MOSIP_DOMAIN}          | `<MOSIP_PUBLIC_IP>`         | Public IP of Nginx server for MOSIP cluster                         | All the API's that are publicly usable are exposed using this domain.                                                                                                                                                                             |
| CNAME Record    | prereg.{MOSIP_DOMAIN}       | api.{MOSIP_DOMAIN}          | Public IP of Nginx server for MOSIP cluster                         | Domain name for MOSIP's pre-registration portal. The portal is accessible publicly.                                                                                                                                                               |
| CNAME Record    | resident.{MOSIP_DOMAIN}     | api.{MOSIP_DOMAIN}          | Public IP of Nginx server for MOSIP cluster                         | Accessing resident portal publicly                                                                                                                                                                                                                |
| CNAME Record    | idp.{MOSIP_DOMAIN}          | api.{MOSIP_DOMAIN}          | Public IP of Nginx server for MOSIP cluster                         | Accessing IDP over public                                                                                                                                                                                                                         |
| CNAME Record    | {MOSIP_DOMAIN}              | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Index page for links to different dashboards of MOSIP env. (This is just for reference, please do not expose this page in a real production or UAT environment)                                                                                   |
| CNAME Record    | activemq.{MOSIP_DOMAIN}     | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Provides direct access to activemq dashboard. It is limited and can be used only over wireguard.                                                                                                                                                  |
| CNAME Record    | kibana.{MOSIP_DOMAIN}       | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Optional installation. Used to access kibana dashboard over wireguard.                                                                                                                                                                            |
| CNAME Record    | regclient.{MOSIP_DOMAIN}    | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Registration Client can be downloaded from this domain. It should be used over wireguard.                                                                                                                                                         |
| CNAME Record    | admin.{MOSIP_DOMAIN}        | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | MOSIP's admin portal is exposed using this domain. This is an internal domain and is restricted to access over wireguard                                                                                                                          |
| CNAME Record    | object-store.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Optional- This domain is used to access the object server. Based on the object server that you choose map this domain accordingly. In our reference implementation, MinIO is used and this domain let's you access MinIO's Console over wireguard |
| CNAME Record    | kafka.{MOSIP_DOMAIN}        | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Kafka UI is installed as part of the MOSIP's default installation. We can access kafka UI over wireguard. Mostly used for administrative needs.                                                                                                   |
| CNAME Record    | iam.{MOSIP_DOMAIN}          | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | MOSIP uses an OpenID Connect server to limit and manage access across all the services. The default installation comes with Keycloak. This domain is used to access the keycloak server over wireguard                                            |
| CNAME Record    | postgres.{MOSIP_DOMAIN}     | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | This domain points to the postgres server. You can connect to postgres via port forwarding over wireguard                                                                                                                                         |
| CNAME Record    | pmp.{MOSIP_DOMAIN}          | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | MOSIP's partner management portal is used to manage partners accessing partner management portal over wireguard                                                                                                                                   |
| CNAME Record    | onboarder.{MOSIP_DOMAIN}    | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Accessing reports of MOSIP partner onboarding over wireguard                                                                                                                                                                                      |
| CNAME Record    | smtp.{MOSIP_DOMAIN}         | api-internal.{MOSIP_DOMAIN} | Private IP of Nginx server for MOSIP cluster                        | Accessing mock-smtp UI over wireguard                                                                                                                                                                                                             |


### Network Requirements

You need to set up the following network infrastructure:

1. **Internal Network**: All VMs, including the deployment node, should be on the same internal/private network wherever possible. The deployment node must be able to SSH to all other nodes and reach the Kubernetes API endpoints without relying on a slow or unstable route.
2. **Public IP Addresses**: You need **two public IP addresses**:
  - **Public API IP**: This IP will be assigned to the MOSIP Nginx server and used for public-facing services (api.{MOSIP_DOMAIN}, prereg.{MOSIP_DOMAIN}, resident.{MOSIP_DOMAIN}, idp.{MOSIP_DOMAIN}). Port 443/tcp
  - **WireGuard IP**: This IP will be assigned to the WireGuard bastion host for secure administrative access over VPN. Port 51820/udp

### Certificate Requirements

You will need valid SSL certificates for HTTPS connections. MOSIP requires:
**NOTE: If your rancher dashboard use same sub-domain the one wildcard certificate is enough**

1. **Wildcard SSL Certificate for Observation Cluster**: A valid wildcard SSL certificate for your observation domain (e.g., `*.{MOSIP_DOMAIN}` or `*.obs.{MOSIP_DOMAIN}`). This certificate needs to be stored on the Observation Nginx server VM.
2. **Wildcard SSL Certificate for MOSIP Cluster**: A valid wildcard SSL certificate for your MOSIP domain (e.g., `*.{MOSIP_DOMAIN}`). This certificate needs to be stored on the MOSIP Nginx server VM.
Note: You can use the same certificate if both DNS records are under the same domain.

The certificates should be in PEM format with:

- Certificate file: `fullchain.pem` (or `cert.pem`)
- Private key file: `privkey.pem` (or `key.pem`)

### VM Requirements

Create the following VMs on your chosen platform (OpenStack, VMware, AWS, Azure, bare metal, etc.). All VMs should run Ubuntu 22.04 LTS and be connected to your internal network. Refer to the [official MOSIP documentation](https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites) for detailed hardware specifications.

**Required VMs:**

1. **deployment-node** (1 VM)
  - **Purpose**: Node from which all deployment operations are executed
  - **Specifications**: 2 vCPU, 4 GB RAM, 20 GB storage
  - **Network**: Internal network, preferably in the same private network as the MOSIP and observation nodes
  - **Additional**: If your deployment node also needs access from an admin network, configure routing appropriately (see deployment node configuration below)
2. **wg-bastion** (1 VM)
  - **Purpose**: WireGuard VPN bastion host for secure administrative access
  - **Specifications**: 2 vCPU, 4 GB RAM, 8 GB storage
  - **Network**: Internal network + **Public IP (WireGuard IP)**
  - **Public IP**: Assign your WireGuard public IP address to this VM
  - **Firewall**: Ensure port 51820/udp is open
3. **mosip-nginx** (1 VM)
  - **Purpose**: Nginx reverse proxy for MOSIP cluster
  - **Specifications**: 2 vCPU, 4 GB RAM, 16 GB storage
  - **Network**: Internal network + **Public IP (Public API IP)**
  - **Public IP**: Assign your public API IP address to this VM
  - **Firewall**: Ensure port 443/tcp is open
4. **observation-node** (1 VM)
  - **Purpose**: Single-node Rancher Observation cluster
  - **Specifications**: 2 vCPU, 8 GB RAM, 32 GB storage
  - **Network**: Internal network
5. **mosip-node** (6 VMs)
  - **Purpose**: Kubernetes cluster nodes for MOSIP (3 control plane + 3 worker nodes, or as per your HA requirements)
  - **Specifications**: 12 vCPU, 32 GB RAM, 128 GB storage each
  - **Network**: Internal network

### Deployment Node Configuration

The deployment node is the machine from which all Ansible playbooks and Terraform operations are executed. Treat it as the deployment control point rather than as a MOSIP application node. It stores the repository checkout, inventories, Terraform variables, kubeconfig files, Helm client configuration, and SSH key used by Ansible.

Create or select this node before starting the rest of the deployment. For AWS deployments, the base Terraform stage creates the MOSIP infrastructure VMs, but you still need to provide the deployment node. A plain Ubuntu 22.04 VM is sufficient for the deployment node as long as it has the required tools installed and network access to the MOSIP private network.

The deployment node should be close to the target infrastructure. The recommended setup is:

- one interface or route for operator/admin access to the deployment node;
- one interface or route into the MOSIP private network;
- passwordless SSH from the deployment node to every MOSIP, observation, Nginx, and WireGuard node;
- stable outbound access to the required Helm chart repositories and package repositories.

Avoid running the main deployment from a laptop over WireGuard if you can use a deployment node inside the same network. WireGuard is useful for administration and verification, but the installation performs many SSH, Helm, Terraform, and Kubernetes API operations. Keeping the deployment node on the same network reduces latency and avoids avoidable communication failures during long-running stages.

**If your deployment node has multiple network interfaces** (e.g., one for admin access and one for MOSIP network access), you may need to configure routing to ensure proper connectivity:

- If both networks use the same gateway, configure route metrics to prioritise the admin network for SSH access
- Alternatively, configure the MOSIP network interface with a static IP and omit the gateway to prevent routing conflicts
- Example netplan configuration for multi-interface setup:
  ```yaml
  network:
    version: 2
    renderer: networkd
    ethernets:
      ens3:  # Admin network interface
          dhcp4: true
          dhcp4-overrides:
            route-metric: 50
      ens4:  # MOSIP network interface
          dhcp4: true
          dhcp4-overrides:
            route-metric: 100
  ```

**SSH Key Configuration:**
- Copy your SSH private key to the deployment node to enable passwordless access to all other nodes:
  ```bash
  scp -i <key-to-connect-to-deployment-node> <ssh-private-key> ubuntu@<deployment-node-ip>:~/.ssh/id_ed25519
  ```
- SSH to the deployment node and set proper permissions:
  ```bash
  ssh ubuntu@<deployment-node-ip>
  chmod 600 ~/.ssh/id_ed25519
  ```
- **Ensure the SSH key is configured with the default naming (`id_ed25519`) so it's automatically used by Ansible**
- **Tool installation**
Based on official requirements [MOSIP Docs 1.2.0](https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/on-prem-installation-guidelines#certificate-requirements)

```
kubectl- any client version above 1.19
helm- any client version above 3.0.0 and add below repos as well:
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo add mosip https://mosip.github.io/mosip-helm
Istioctl : version: 1.15.0
rke : version: 1.3.10
Ansible version > 2.12.4
```

Our Deployment:

- With 22.04 use Ansible apt package.
- Helm and Kubectl are in snap store

```
sudo apt -y install ansible jq certbot python3-certbot-dns-route53
sudo snap install kubectl --classic
sudo snap install helm --classic
sudo snap install terraform --classic
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add mosip https://mosip.github.io/mosip-helm
```

- OpenSSL 1.1.1f
For regclient certificate there is a dependency to use openssl 1.1.1f, install it manually. Otherwise you get an error during deployment `jarsigner error: java.lang.RuntimeException: keystore load: keystore password was incorrect`

```
mkdir openssl; cd openssl;
# download binary openssl packages from Impish builds
wget https://security.ubuntu.com/ubuntu/pool/main/o/openssl/openssl_1.1.1f-1ubuntu2_amd64.deb
wget https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2_amd64.deb
wget https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb

# install downloaded binary packages
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i libssl-dev_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i openssl_1.1.1f-1ubuntu2_amd64.deb
```

- Istioctl (version depends on `kubernetes_engine` in `group_vars/all.yml`)

```sh
# RKE2 default (kubernetes_engine=rke2)
cd ~; mkdir istioctl-1.22.0 ; cd istioctl-1.22.0/
wget https://github.com/istio/istio/releases/download/1.22.0/istioctl-1.22.0-linux-amd64.tar.gz
tar -xzf istioctl-1.22.0-linux-amd64.tar.gz
sudo cp istioctl /usr/local/bin
istioctl version

# Legacy RKE1 only (kubernetes_engine=rke1)
# cd ~; mkdir istioctl-1.15.0 ; cd istioctl-1.15.0/
# wget https://github.com/istio/istio/releases/download/1.15.0/istioctl-1.15.0-linux-amd64.tar.gz
# tar -xzf istioctl-1.15.0-linux-amd64.tar.gz
# sudo cp istioctl /usr/local/bin
```

- RKE2 cluster engine (default). RKE1 binary only required for legacy `kubernetes_engine=rke1`.

```sh
# No RKE/RKE2 binary needed on deployment-node for default RKE2 path.
# Ansible installs RKE2 via get.rke2.io on cluster nodes.

# Legacy RKE1 only:
# cd ~; wget https://github.com/rancher/rke/releases/download/v1.3.10/rke_linux-amd64
# chmod +x rke_linux-amd64
# sudo mv rke_linux-amd64 /usr/local/bin/rke
# rke --version
```

Set `kubernetes_engine: rke2` (default) and `rke2_version: "v1.28.9+rke2r1"` in `inventory/group_vars/all.yml`. Use `kubernetes_engine: rke1` only for legacy clusters.

**RKE2 paths (default):**
- Main cluster kubeconfig: `{rancher_base_dir}/{cluster_name}/kube_config_cluster.yml` (e.g. `/home/ubuntu/rancher/mosip/kube_config_cluster.yml`)
- Main cluster token: `{rancher_base_dir}/{cluster_name}/rke2_token`
- OBS cluster kubeconfig: `{rancher_obs_base_dir}/kube_config_cluster.yml` (e.g. `/home/ubuntu/rancher/obs/kube_config_cluster.yml`)
- OBS cluster token: `{rancher_obs_base_dir}/rke2_token`

Code repo:

- Clone the repositorie:

```sh
mkdir ~/mosip; cd ~/mosip
git clone https://github.com/alan-turing-institute/automating-mosip-deployment.git
```

- Generate SSL certs `[OPTIONAL]` if you don't use your company wildcard cert.

```
# Using AWS Route53
sudo certbot -v certonly --dns-route53 --agree-tos --preferred-challenges=dns -d *.{MOSIP_DOMAIN} -d {MOSIP_DOMAIN}

# Manual DNS route
sudo certbot certonly --agree-tos --manual --preferred-challenges=dns -d *.{MOSIP_DOMAIN} -d {MOSIP_DOMAIN}

# NOTE: With manual DNS route you might be asked to create two identical TXT records with different values. It's allowed in DNS standard, do not remove the 1st record!!!
Successfully received certificate.  
Certificate is saved at: /etc/letsencrypt/live/{MOSIP_DOMAIN}/fullchain.pem  
Key is saved at:         /etc/letsencrypt/live/{MOSIP_DOMAIN}/privkey.pem  
This certificate expires on 2026-02-17.  
These files will be updated when the certificate renews.
```

## AWS provisioning

- Run this stage only for AWS deployments.
- This stage is infrastructure provisioning only (declarative Terraform). Keep host configuration and bootstrap in Ansible stages below.
- **[OPTIONAL]** Enable Route53 DNS record creation in `aws.tfvars` file. See section [AWS DNS](#optional-aws-dns-and-certbot-automation)
- After applying, map Terraform outputs into existing inventory and tfvars files, then proceed with the unchanged deployment sequence.

### Terraform apply (AWS base only)

```bash
cd ~/mosip/automating-mosip-deployment/terraform/aws/base-infra
cp aws.tfvars.tmp aws.tfvars
terraform init
terraform plan -var-file=aws.tfvars
terraform apply -var-file=aws.tfvars
terraform output -json > aws-base-outputs.json
```

### Map AWS outputs to existing templates

Use the outputs from `aws-base-outputs.json` to populate existing files without changing their structure:


| Target file                                             | Existing field(s) to set                                                                                     | AWS base output source                                                                                                                                |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ansible/wireguard/inventory/hosts.ini`                 | `ansible_host`, `wireguard_endpoint` for `wireguard-node`                                                    | jumpserver private IP, jumpserver public IP                                                                                                           |
| `ansible/infra_deployment/inventory/rancher.ini`        | `physical_vms`, `control_plane_nodes`, `etcd_nodes`, `worker_nodes`, `mosip_obs`, `nginx`, `nginx_obs` hosts | `physical_vm_private_ips`, `control_plane_node_ips`, `etcd_node_ips`, `worker_node_ips`, `obs_private_ip`, `nginx_private_ip`, `nginx_obs_private_ip` |
| `ansible/infra_deployment/inventory/group_vars/all.yml` | `nginx_obs_public_domain_names`, `mosip_domain`, `rancher_import_url` (later step)                           | DNS names derived from deployment domain and Rancher import URL from OBS stage                                                                        |
| `terraform/obs_deployment/terraform.tfvars`             | `rancher_hostname`, `kubeconfig_path`                                                                        | `rancher.<MOSIP_DOMAIN>`, existing kubeconfig path                                                                                                    |
| `terraform/mosip_deployment/terraform.tfvars`           | `installation_domain`, `kubeconfig_path`                                                                     | `<MOSIP_DOMAIN>`, existing kubeconfig path                                                                                                            |


### Optional AWS DNS and certbot automation

You can optionally automate DNS and certbot IAM/profile provisioning in `terraform/aws/base-infra/aws.tfvars`:

- DNS automation toggle:
  - `enable_route53_records = true`
  - required: `cluster_env_domain`, `route53_zone_id`
- Certbot IAM/profile toggle:
  - `enable_certbot_iam_profile = true`
  - This creates IAM role/policy/instance-profile resources for nginx node Route53 DNS challenge automation.
  - This requires IAM write permissions (for example `iam:CreatePolicy`, `iam:CreateInstanceProfile`, role/policy attachment actions).
  - If your AWS identity cannot create IAM resources, keep this as `false`.
- Optional root-domain record:
  - `enable_root_domain_record = true`
  - `root_domain_record_type = "A"` (required)

When DNS automation is enabled, Route53 records include:

- A records: `api`, `api-internal`, and OBS A records (`rancher`, `rancher-keycloak` by default)
- CNAME records:
  - public: `prereg`, `resident`, `idp`, `admin` -> `api.<MOSIP_DOMAIN>`
  - internal: `activemq`, `kibana`, `regclient`, `object-store`, `kafka`, `iam`, `postgres`, `pmp`, `onboarder`, `smtp`, `minio`, `esignet`, `healthservices`, `signup` -> `api-internal.<MOSIP_DOMAIN>`

#### If using AWS without certbot IAM profile

- You can still issue certificates using existing local AWS credentials with Route53 access:

```bash
sudo certbot -v certonly --dns-route53 --agree-tos --preferred-challenges=dns -d *.warwick-1.turing-mosip.net -d warwick-1.turing-mosip.net
```

- Replace domain values with your deployment domain.
- If this command is not available in your environment, you must provide certificates manually before continuing.
- Required files for next stages: `fullchain.pem` and `privkey.pem`.

### Update Ansible inventory file

#### Wireguard hosts

Wireguard Ansible is a whole separate playbooks as it can sit completely independent from the rest of MOSIP infrastructure.

- Copy the `hosts.ini.tmp` to `host.ini`, make sure you set both `ansible_host` and assign public ip to `wireguard_endpoint`

```
cd ~/mosip/automating-mosip-deployment/ansible/wireguard/inventory
cp hosts.ini.tmp hosts.ini

[wireguard]
wireguard-node ansible_host=<wg-bastion-public-ip> wireguard_endpoint=<wireguard-public-ip>
```

#### Infra hosts

- Copy the `rancher.ini.tmp` to `rancher.ini` then update all HOSTS to match your VM deployment. The control_plane and etcd nodes are usually the same first three VMs, and workers are typically VMs four to six. The Observation node is usually one VM and Observation Nginx can be the same VM or a separate one.
- Copy the `group_vars/all.yml.tmp` to `group_vars/all.yml`
- **Important**: Replace all IP addresses in the example below with your actual VM IP addresses from your internal network.

Example inventory structure (replace IPs with your actual values):

```
cd ~/mosip/automating-mosip-deployment/ansible/infra_deployment/inventory

[physical_vms]
# Physical VMs where nodes are running
vm1 ansible_host=<node1-private-ip>
vm2 ansible_host=<node2-private-ip>
vm3 ansible_host=<node3-private-ip>
vm4 ansible_host=<node4-private-ip>
vm5 ansible_host=<node5-private-ip>
vm6 ansible_host=<node6-private-ip>

[control_plane_nodes]
# Control plane nodes - responsible for managing the cluster
control-1 physical_vm=vm1 node_ip=<node1-private-ip>
control-2 physical_vm=vm2 node_ip=<node2-private-ip>
control-3 physical_vm=vm3 node_ip=<node3-private-ip>

[etcd_nodes]
# etcd nodes - responsible for storing cluster state
etcd-1 physical_vm=vm1 node_ip=<node1-private-ip>
etcd-2 physical_vm=vm2 node_ip=<node2-private-ip>
etcd-3 physical_vm=vm3 node_ip=<node3-private-ip>

[worker_nodes]
# Worker nodes - where applications run
worker-1 physical_vm=vm4 node_ip=<node4-private-ip>
worker-2 physical_vm=vm5 node_ip=<node5-private-ip>
worker-3 physical_vm=vm6 node_ip=<node6-private-ip>

[rancher_nodes:children]
control_plane_nodes
etcd_nodes
worker_nodes

[mosip_obs]
# Single node Rancher OBS cluster
obs-node-1 ansible_host=<observation-node-private-ip>

[nginx]
# Add your nginx nodes here
nginx-node-1 ansible_host=<mosip-nginx-private-ip>

[nginx_obs]
# Add your OBS nginx nodes here
nginx-obs-node-1 ansible_host=<obs-nginx-private-ip>
```

### Update all nodes

In Ansible we have playbook to do `apt update && apt -y upgrade` on all hosts to streamline the deployment later. This role can also be used to install additional packages and expand in the future with additional configs.

```
cd ~/mosip/automating-mosip-deployment/ansible/infra_deployment
ansible-playbook -f 12 -v -i inventory/rancher.ini playbooks/apt-upgrade.yml
```

## Wireguard deployment

- From `deployment-node`
- **Public IP**: Ensure your WireGuard public IP is assigned to the `wg-bastion` VM
- SSH to wg-bastion and run `sudo apt update && sudo apt upgrade -y`
- Check wireguard inventory file is ready. 
- Run Ansible: `ansible-playbook -v -i inventory/hosts.ini playbooks/wireguard.yml`
- Get WG peer config: `ssh ubuntu@<wg-bastion-public-ip> "sudo cat /root/wireguard/config/peer1/peer1.conf"` and save on your laptop machine
- **MTU Configuration**: Default MTU is `1330` in generated peer/client WireGuard configs. Use this as the baseline across cloud providers to avoid fragmentation issues on overlay/network-edge paths. Override only if your specific network requires a different MTU.
- **Port Configuration**: Ensure your firewall allows UDP traffic on port 51820 (or the port configured in your WireGuard setup) to the WireGuard public IP.
- Test the setup on your client laptop:
  ```bash
  sudo vim /etc/wireguard/wg1-{MOSIP_DOMAIN}.conf
  sudo systemctl start wg-quick@wg1-{MOSIP_DOMAIN}
  ssh <any host on internal network>
  ```

## Observation node deployment

- From `deployment-node`
- Check infra inventory file is ready.
- In `inventory/group_vars/all.yml` update:
  - Nginx OBS hostname: `nginx_obs_public_domain_names`
  - Mosip domain: `mosip_domain`
- Copy wildcard certificate to `ansible/infra_deployment/playbooks/roles/nginx_obs/files` make sure the name is: `fullchain.pem` and `privkey.pem`
- Run Ansible `ansible-playbook -v -i inventory/rancher.ini playbooks/deploy-rke2-obs.yml`
  - Legacy RKE1: `playbooks/deploy-rancher-obs.yml`

### Verification

- `kubectl get pods --all-namespaces` - all pods needs to be in Running or Completed
- `curl https://rancher.{MOSIP_DOMAIN}` - It will show 502 for now as Helm is not yet deployed

### Terraform

- `cd ~/mosip/automating-mosip-deployment/terraform/obs_deployment`
- Copy the `terraform.tfvars.tmp` to `terraform.tfvars`, make sure you set both `rancher_hostname` to your MOSIP rancher DNS (e.g., `rancher.{MOSIP_DOMAIN}`) and `kubeconfig_path` is correct and use full path instead of `~`
- Run terraform init `terraform init`
- Run terraform plan `terraform plan`, check the hostname match the ansible `nginx_obs_public_domain_names`
- Run terraform apply: `terraform apply`

### Verification

- `kubectl get pods --all-namespaces` - all pods needs to be in Running or Completed
- `curl https://rancher.{MOSIP_DOMAIN}` - It will redirect to Rancher dashboard
- Get IMPORT url from Rancher dashboard. Click Import Existing - Generic - Cluster Name (e.g., `mosip-cluster`) - Create - Copy URL only, e.g. `https://rancher.{MOSIP_DOMAIN}/v3/import/<import-token>.yaml`

## Infra deployment

- From  `deployment-node`
- Check infra inventory file is ready.
- In `inventory/group_vars/all.yml` , update `rancher_import_url`
- Copy wildcard certificate to `~/mosip/automating-mosip-deployment/ansible/infra_deployment/playbooks/roles/nginx/files` make sure the name is: `fullchain.pem` and `privkey.pem`
- Run Ansible `ansible-playbook -f 8 -v -i inventory/rancher.ini playbooks/deploy-all-rke2.yml`
  - Legacy RKE1: `playbooks/deploy-all.yml`

### Verification

- `kubectl get pods --all-namespaces` - all pods needs to be in Running or Completed
- `curl https://{MOSIP_DOMAIN}` - It will show 502 for now as Helm is not yet deployed

## MOSIP deployment

**IMPORTANT: It is expected for the Terraform plan and apply stages to take time. MOSIP is a large system, and Terraform must calculate a substantial Helm/Kubernetes deployment graph before applying changes.**

The final MOSIP stage is usually the longest part of the deployment. A complete first deployment commonly takes several hours. Some modules are deployed sequentially because later modules depend on earlier ones being available, so not every chart can be installed in parallel.

For MOSIP 1.2.0.2, some services may take 20-30 minutes to initialise before Kubernetes reports them as ready. This is common for `config-server` and parts of the `regproc` family. The automation uses long Helm timeout windows and delayed startup/readiness/liveness probes because testing showed that checking too early can cause otherwise healthy modules to be restarted or marked as failed before they finish initialising.

During this stage, long periods of output such as `Still creating... [20m10s elapsed]` do not automatically mean that Terraform has frozen. In many cases Terraform has already asked Helm to deploy the chart and is polling the release status while Kubernetes waits for the pods to become healthy.

- `cd ~/mosip/automating-mosip-deployment/terraform/mosip_deployment`
- Copy the `terraform.tfvars.tmp` to `terraform.tfvars`, make sure you set both `installation_domain` to your MOSIP domain (e.g., `{MOSIP_DOMAIN}`) and `kubeconfig_path` is correct and use full path instead of `~`
- `cd infra`
- Run terraform init `terraform init`
- Run terraform plan `terraform plan -var-file=../terraform.tfvars`
- Run terraform apply: `terraform apply -var-file=../terraform.tfvars`
- `cd ../mosip`
- Run terraform init `terraform init`
- Run terraform plan `terraform plan -var-file=../terraform.tfvars`
- Run terraform apply: `terraform apply -var-file=../terraform.tfvars`

### Verification

- `kubectl get pods --all-namespaces` - all pods needs to be in Running or Completed
- `curl https://{MOSIP_DOMAIN}` - It will redirect to MOSIP landing page

## Troubleshooting

### Long-running MOSIP modules

In the event that a MOSIP module deployment fails, it is safe to re-run the Terraform apply stage. Terraform will check the Helm deployment status, detect the failed release, and remove and redeploy the affected module before continuing.

Long-running modules are expected. A module that is still creating after 20 minutes may simply be waiting for MOSIP to initialise. Before interrupting the deployment, check the relevant pods:

```bash
kubectl get pods --all-namespaces
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --all-containers
```

If Terraform reaches the 30-minute timeout for a module, wait a few more minutes and check the pods again. Sometimes the pod restarts once or twice and then becomes healthy. If the module later shows all containers as Running, for example `2/2 Running` or `3/3 Running`, you can update the Helm release status without forcing Terraform to redeploy it:

```bash
helm upgrade regproc-reprocess mosip/regproc-reprocess -n regproc --reuse-values --version 12.0.1
```

Use the same chart version that Terraform is configured to deploy. The command above reuses the existing values and lets Helm record the release as successfully upgraded. When Terraform is run again, it can detect that the module is healthy and continue with the next module. **Warning**: if you do not use the same chart version, Helm may try to upgrade to the latest chart in the repository and Terraform may still detect drift or redeploy the release.

### Chart repository or network timeouts

Temporary chart repository or network errors can also happen during long deployments. Examples include:

- `could not download chart`
- `context deadline exceeded`
- `failed get OpenAPI spec`
- `failed to determine resource type ID`

These usually indicate a temporary communication problem between the deployment node and an external chart repository, or between the deployment node and the Kubernetes API. They do not necessarily mean that the automation or MOSIP chart is wrong. Check connectivity from the deployment node, confirm that the Helm repositories are reachable, and confirm that the Kubernetes API is responsive:

```bash
helm repo update
kubectl get nodes
kubectl get pods --all-namespaces
```

If the checks succeed, re-run the same Terraform apply command. Terraform is declarative and will continue from the current state where possible.