# MOSIP deployment

> **Reference Documentation**: This deployment guide provides step-by-step instructions for deploying MOSIP. For comprehensive information about hardware requirements, network architecture, certificate requirements, and other prerequisites, please refer to the official MOSIP documentation at [https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites](https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites). The official documentation contains detailed specifications for VM sizing, network requirements, DNS configuration, and certificate management that should be reviewed before beginning deployment.

## Introduction

This document is the working deployment plan for installing MOSIP 1.2.0.2 with the Turing automation framework. Replace placeholder values (domain, IPs, paths) with your environment details.

The repository is an automation framework for the MOSIP deployment process. It uses the same MOSIP Helm charts and chart repositories as the official MOSIP deployment flow. It does not modify MOSIP application code, patch MOSIP modules, or replace MOSIP's own chart logic. The purpose of this framework is to make the official deployment process more repeatable, easier to verify, and easier to re-run when a step needs to be repeated.

## How this guide is organized

Follow these phases in order:

1. **Deployment node** — create the operator VM, connect it to the MOSIP network, install tools, clone this repository.
2. **Infrastructure path** — choose **AWS** (Terraform base infra) or **on-prem** (you provision VMs, DNS, and certificates).
3. **Shared deployment** — the same Ansible and Terraform sequence for both paths: inventory → WireGuard → OBS RKE2 cluster → main RKE2 cluster → MOSIP Terraform.

All commands in phases 2 and 3 are run **from the deployment node**.

---

## Phase 1 — Deployment node (start here)

### Why the deployment node comes first

Every Ansible playbook, Terraform apply, Helm operation, and `kubectl` check in this automation is designed to run from a dedicated **deployment node**. This machine is not a MOSIP application node; it is the control point that:

- SSHs to every WireGuard, Nginx, observation, and MOSIP cluster node (hundreds of times during a full install).
- Holds the repository checkout, inventories, Terraform variables, kubeconfig files, and the SSH key Ansible uses.
- Talks to the Kubernetes API repeatedly while Helm releases and MOSIP modules become healthy (installs can run for hours).

**Why network placement matters:** Ansible copies scripts and configuration to remote hosts. Terraform and Helm poll the Kubernetes API while waiting for pods. If the deployment node reaches the cluster over a high-latency path, a VPN-only route, or an unstable link, you are more likely to see SSH drops, chart download failures, and API timeouts — especially during the long MOSIP Terraform stage.

**Recommended setup:** put the deployment node on the **same private network** as the MOSIP and observation VMs. You may keep one interface or route for operator/admin access (SSH to the deployment node from your laptop) and a second interface or route into the MOSIP private network. WireGuard is for day-to-day admin access to the environment; avoid running the main install from a laptop over WireGuard when a co-located deployment node is available.

You may power off the deployment node after installation and use it again for day-two operations (Terraform variable changes, Ansible re-runs, upgrades).

### Step 1 — Create the deployment node VM

| Item | Value |
|------|--------|
| OS | **Ubuntu 26.04 LTS** |
| Purpose | Operator workstation for Ansible, Terraform, Helm, `kubectl`, certificates, inventory |
| Size | 2 vCPU, 4 GB RAM, 20 GB storage |
| Not included in | AWS base Terraform (you provision this VM yourself in both AWS and on-prem flows) |

Before continuing, decide how you will connect this VM to the MOSIP network (Step 2).

### Step 2 — Connect the deployment node to the MOSIP network

The deployment node must reach every target VM by **private IP** and SSH. How you achieve that depends on your infrastructure path:

#### Option A — AWS deployment

1. You will run AWS base Terraform (Phase 2) to create the VPC, subnets, and MOSIP infrastructure VMs.
2. The deployment node is **not** created by that Terraform module — provision it separately (same cloud account or your admin network).
3. Attach a **second network interface** (or equivalent routing) so the deployment node sits on the **same VPC private network** as the WireGuard, Nginx, observation, and MOSIP nodes output by Terraform.
4. From the deployment node, verify SSH to private IPs of all provisioned nodes before starting Ansible.

Use private IPs from `terraform output` when filling Ansible inventories after AWS apply.

#### Option B — On-prem deployment

1. Create all infrastructure VMs yourself (see [On-prem prerequisites](#option-b--on-prem-prerequisites) for sizing and roles).
2. Place the deployment node on the **same internal/private network** as those VMs.
3. If the deployment node also needs access from a separate admin network, configure routing so admin SSH works without breaking reachability to MOSIP private IPs.

**Multi-interface example** (both options — admin network + MOSIP network):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:  # Admin network — SSH from your laptop
      dhcp4: true
      dhcp4-overrides:
        route-metric: 50
    ens4:  # MOSIP private network — Ansible / kubectl targets
      dhcp4: true
      dhcp4-overrides:
        route-metric: 100
```

Adjust interface names and use static IPs where your platform requires them. If the MOSIP interface should not use the admin gateway, omit `gateway4` on that interface to avoid routing conflicts.

### Step 3 — Configure SSH access from the deployment node

Copy your SSH private key to the deployment node so Ansible can reach all other hosts without prompts:

```bash
scp -i <key-to-connect-to-deployment-node> <ssh-private-key> ubuntu@<deployment-node-ip>:~/.ssh/id_ed25519
ssh ubuntu@<deployment-node-ip>
chmod 600 ~/.ssh/id_ed25519
```

Use the default name `id_ed25519` so Ansible picks it up automatically (`ansible_ssh_private_key_file` in inventory).

### Step 4 — Install deployment tools

Clusters use **RKE2** (Ansible installs it on nodes — no `rke` binary on the deployment node). Install **istioctl 1.22.0** to match the Istio version deployed with the main cluster.

On Ubuntu 26.04:

```sh
sudo apt update
sudo apt -y install ansible jq git curl wget unzip ca-certificates openssh-client python3 python3-pip certbot python3-certbot-dns-route53

sudo snap install kubectl --classic
sudo snap install helm --classic
sudo snap install terraform --classic

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add mosip https://mosip.github.io/mosip-helm
helm repo update
```

**istioctl 1.22.0:**

```sh
ISTIO_VERSION=1.22.0
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -
sudo install -o root -g root -m 0755 istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/istioctl
istioctl version --remote=false
```

Quick check:

```sh
ansible --version | head -1
kubectl version --client
helm version
terraform version
istioctl version --remote=false
helm repo list | grep -E 'bitnami|mosip'
```

### Step 5 — Clone the repository

```sh
mkdir ~/mosip && cd ~/mosip
git clone https://github.com/alan-turing-institute/automating-mosip-deployment.git
cd automating-mosip-deployment
```

Configure inventories and Terraform variables in Phase 2/3 once you know your domain and IP addresses.

---

## Phase 2 — Choose your infrastructure path

| | Option A — AWS | Option B — On-prem |
|---|----------------|---------------------|
| Who creates VMs | Terraform `aws/base-infra` (except deployment node) | You (OpenStack, VMware, bare metal, etc.) |
| DNS | Optional Route53 automation in Terraform | Manual (or your DNS team) |
| Deployment node network | Add 2nd NIC / route into VPC private network | Same internal network as cluster VMs |
| Then | Continue to [Phase 3](#phase-3--shared-deployment-sequence) | Continue to [Phase 3](#phase-3--shared-deployment-sequence) |

Define **`{MOSIP_DOMAIN}`** once (e.g. `mosip.example.com` or `sandbox.example.org`) and use it throughout both paths.

---

### Option A — AWS base infrastructure

Run this stage only for AWS deployments. Terraform here is **declarative infrastructure only** — host configuration and RKE2 bootstrap remain in Ansible (Phase 3).

**Optional:** enable Route53 DNS in `aws.tfvars` — see [Optional AWS DNS](#optional-aws-dns-and-certbot-automation).

#### Terraform apply

```bash
cd ~/mosip/automating-mosip-deployment/terraform/aws/base-infra
cp aws.tfvars.tmp aws.tfvars # Min changes ssh_key_name.
terraform init
terraform plan -var-file=aws.tfvars
terraform apply -var-file=aws.tfvars
terraform output -json > aws-base-outputs.json
```

#### Add MOSIP-NET interface to deployment node
Once your MOSIP network is created, we can create network interface and attach to the deployment VM.


#### Map AWS outputs to Ansible / Terraform templates

Use `aws-base-outputs.json` to populate existing files:

| Target file | Field(s) to set | AWS output source |
|-------------|-----------------|-------------------|
| `ansible/wireguard/inventory/hosts.ini` | `ansible_host`, `wireguard_endpoint` | jumpserver private/public IP |
| `ansible/infra_deployment/inventory/rancher.ini` | `physical_vms`, RKE2 groups, `mosip_obs`, `nginx`, `nginx_obs` | `physical_vm_private_ips`, node IPs, `obs_private_ip`, nginx IPs |
| `ansible/infra_deployment/inventory/group_vars/all.yml` | `mosip_domain`, `nginx_obs_public_domain_names`, `rancher_import_url` (later) | your domain; Rancher URL after OBS stage |
| `terraform/obs_deployment/terraform.tfvars` | `rancher_hostname`, `kubeconfig_path` | `rancher.{MOSIP_DOMAIN}`, OBS kubeconfig path |
| `terraform/mosip_deployment/terraform.tfvars` | `installation_domain`, `kubeconfig_path` | `{MOSIP_DOMAIN}`, main kubeconfig path |

**After AWS apply:** confirm the deployment node can `ssh ubuntu@<private-ip>` to every node. If not, fix Step 2 (second interface / routing) before Phase 3.

#### Optional AWS DNS and certbot automation

In `terraform/aws/base-infra/aws.tfvars`:

- **DNS:** `enable_route53_records = true`, `cluster_env_domain`, `route53_zone_id`
- **Certbot IAM:** `enable_certbot_iam_profile = true` (requires IAM permissions; set `false` if your identity cannot create IAM resources)
- **Root domain:** `enable_root_domain_record = true`, `root_domain_record_type = "A"`

When DNS automation is enabled, Route53 records include A records for `api`, `api-internal`, OBS hosts, and CNAMEs for MOSIP service hostnames (see previous MOSIP DNS table for the full list).

**Without certbot IAM profile** — issue certs manually on the deployment node:

```bash
sudo certbot -v certonly --dns-route53 --agree-tos --preferred-challenges=dns \
  -d *.{MOSIP_DOMAIN} -d {MOSIP_DOMAIN}
```

Provide `fullchain.pem` and `privkey.pem` before Nginx/OBS stages.

---

### Option B — On-prem prerequisites

For on-prem, you create all resources listed below before Phase 3. The deployment node should already be on the internal network (Phase 1, Step 2, Option B).

#### Domain and DNS

Configure DNS for `{MOSIP_DOMAIN}`. Replace IPs with your infrastructure:


| **Record Type** | **Domain Name** | **IP/DNS** | **Purpose** |
| --------------- | --------------- | ---------- | ----------- |
| A Record | rancher.{MOSIP_DOMAIN} | `<OBS_NGINX_PRIVATE_IP>` | Rancher dashboard |
| A Record | keycloak.{MOSIP_DOMAIN} | `<OBS_NGINX_PRIVATE_IP>` | Keycloak (cluster admin IAM) |
| A Record | api-internal.{MOSIP_DOMAIN} | `<MOSIP_NGINX_PRIVATE_IP>` | Internal APIs (WireGuard) |
| A Record | api.{MOSIP_DOMAIN} | `<MOSIP_PUBLIC_IP>` | Public APIs |
| CNAME | prereg.{MOSIP_DOMAIN} | api.{MOSIP_DOMAIN} | Pre-registration portal |
| CNAME | resident.{MOSIP_DOMAIN} | api.{MOSIP_DOMAIN} | Resident portal |
| CNAME | idp.{MOSIP_DOMAIN} | api.{MOSIP_DOMAIN} | IDP |
| CNAME | {MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Landing page (internal reference) |
| CNAME | activemq.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | ActiveMQ dashboard |
| CNAME | kibana.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Optional — Kibana |
| CNAME | regclient.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Registration client download |
| CNAME | admin.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Admin portal |
| CNAME | object-store.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Optional — MinIO console |
| CNAME | kafka.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Kafka UI |
| CNAME | iam.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Keycloak (MOSIP IAM) |
| CNAME | postgres.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Postgres (port-forward) |
| CNAME | pmp.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Partner management portal |
| CNAME | onboarder.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Partner onboarding reports |
| CNAME | smtp.{MOSIP_DOMAIN} | api-internal.{MOSIP_DOMAIN} | Mock SMTP UI |

#### Network

1. **Internal network:** all VMs (including deployment node) on the same private network where possible.
2. **Two public IPs:**
   - **Public API IP** → MOSIP Nginx (`443/tcp`) — api, prereg, resident, idp
   - **WireGuard IP** → WireGuard bastion (`51820/udp`)

#### Certificates

Wildcard PEM for observation and MOSIP Nginx (can be one cert if same domain):

- `fullchain.pem`
- `privkey.pem`

**Optional — generate on deployment node** if you do not use a corporate wildcard:

```bash
# AWS Route53
sudo certbot -v certonly --dns-route53 --agree-tos --preferred-challenges=dns \
  -d *.{MOSIP_DOMAIN} -d {MOSIP_DOMAIN}

# Manual DNS
sudo certbot certonly --agree-tos --manual --preferred-challenges=dns \
  -d *.{MOSIP_DOMAIN} -d {MOSIP_DOMAIN}
```

With manual DNS, you may need two TXT records with different values — both are allowed; do not remove the first before validation completes.

#### VMs to create

Cluster nodes: Ubuntu 22.04 or 24.04 LTS per [official MOSIP docs](https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites) until 26.04 is validated for cluster nodes.

| VM | Count | vCPU | RAM | Disk | Network |
|----|-------|------|-----|------|---------|
| deployment-node | 1 | 2 | 4 GB | 20 GB | Internal (+ admin access as needed) — **Phase 1** |
| wg-bastion | 1 | 2 | 4 GB | 8 GB | Internal + WireGuard public IP |
| mosip-nginx | 1 | 2 | 4 GB | 16 GB | Internal + public API IP |
| observation-node | 1 | 2 | 8 GB | 32 GB | Internal |
| mosip-node | 6 | 12 | 32 GB | 128 GB each | Internal |

---

## Phase 3 — Shared deployment sequence

Run all steps below **from the deployment node** after Phase 1 is complete and Phase 2 (AWS or on-prem) has provided VMs, DNS, and certificates.

**RKE2 kubeconfig paths (defaults):**

| Cluster | Kubeconfig | Token |
|---------|------------|-------|
| Main (`mosip`) | `{rancher_base_dir}/{cluster_name}/kube_config_cluster.yml` | `.../rke2_token` |
| OBS | `{rancher_obs_base_dir}/kube_config_cluster.yml` | `.../rke2_token` |

Example: `/home/ubuntu/rancher/mosip/kube_config_cluster.yml`, `/home/ubuntu/rancher/obs/kube_config_cluster.yml`

### Prepare Ansible inventory

Edit inventory files under the repo with your IP addresses and domain. Examples and field names are in the `*.tmp` files alongside each inventory if you need a reference.

#### WireGuard

File: `ansible/wireguard/inventory/hosts.ini`

```
[wireguard]
wireguard-node ansible_host=<wg-bastion-private-ip> wireguard_endpoint=<wireguard-public-ip>
```

#### Infra (RKE2)

Files: `ansible/infra_deployment/inventory/rancher.ini`, `group_vars/all.yml`

Set `mosip_domain`, `nginx_obs_public_domain_names`, and all `ansible_host` values.

**RKE2 inventory structure** (replace IPs):

```
[physical_vms]
vm1 ansible_host=<node1-private-ip>
vm2 ansible_host=<node2-private-ip>
...
vm6 ansible_host=<node6-private-ip>

[control_plane_primary]
vm1 ansible_host=<node1-private-ip>

[control_plane_subsequent]
vm2 ansible_host=<node2-private-ip>
vm3 ansible_host=<node3-private-ip>

[rke2_agents]
vm4 ansible_host=<node4-private-ip>
vm5 ansible_host=<node5-private-ip>
vm6 ansible_host=<node6-private-ip>

[rke2_etcd]
# empty = embedded etcd on servers

[mosip_obs]
obs-node-1 ansible_host=<observation-node-private-ip>

[nginx]
nginx-node-1 ansible_host=<mosip-nginx-private-ip>

[nginx_obs]
nginx-obs-node-1 ansible_host=<obs-nginx-private-ip>
```

Topology default: vm1 = primary control plane; vm2–vm3 = HA control plane; vm4–vm6 = worker agents.

Set `rancher_hostname`, `kubeconfig_path`, and `installation_domain` in the Terraform tfvars under `terraform/obs_deployment/` and `terraform/mosip_deployment/` before the Terraform stages below.

### Update all nodes (optional but recommended)

```bash
cd ~/mosip/automating-mosip-deployment/ansible/infra_deployment
ansible-playbook -f 12 -v -i inventory/rancher.ini playbooks/apt-upgrade.yml
```

### WireGuard deployment

- Ensure WireGuard public IP is on `wg-bastion`; port `51820/udp` open.
- On wg-bastion: `sudo apt update && sudo apt upgrade -y`
- From deployment node:

```bash
cd ~/mosip/automating-mosip-deployment/ansible/wireguard
ansible-playbook -v -i inventory/hosts.ini playbooks/wireguard.yml
```

- Fetch peer config: `ssh ubuntu@<wg-bastion-public-ip> "sudo cat /root/wireguard/config/peer1/peer1.conf"`
- Default MTU in peer configs: **1330** (adjust only if your network requires it).
- Test from laptop:

```bash
sudo systemctl start wg-quick@wg1-{MOSIP_DOMAIN}
ssh ubuntu@<any-internal-host-ip>
```

### Observation node (RKE2 + Rancher stack)

- In `group_vars/all.yml`: set `nginx_obs_public_domain_names`, `mosip_domain`
- Place wildcard cert as `fullchain.pem` and `privkey.pem` in `playbooks/roles/nginx_obs/files/`

```bash
cd ~/mosip/automating-mosip-deployment/ansible/infra_deployment
ansible-playbook -v -i inventory/rancher.ini playbooks/deploy-rancher-obs.yml
```

**Verify:** `kubectl get pods -A` (OBS kubeconfig); `curl https://rancher.{MOSIP_DOMAIN}` → 502 until Terraform OBS apply.

**Terraform OBS:**

```bash
cd ~/mosip/automating-mosip-deployment/terraform/obs_deployment
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

**Verify:** Rancher UI loads; copy import URL from Rancher → **Import Existing → Generic** → paste into `rancher_import_url` in `group_vars/all.yml`.

### Main cluster (RKE2 + Istio)

- Place wildcard cert as `fullchain.pem` and `privkey.pem` in `playbooks/roles/nginx/files/`

```bash
cd ~/mosip/automating-mosip-deployment/ansible/infra_deployment
ansible-playbook -f 8 -v -i inventory/rancher.ini playbooks/deploy-all.yml
```

**Verify:** `kubectl get pods -A`; `curl https://{MOSIP_DOMAIN}` → 502 until MOSIP infra Terraform.

### MOSIP Terraform (infra then services)

**Expect long runtimes** — first apply often takes hours. Modules deploy sequentially; `config-server` and `regproc` may need 20–30 minutes before probes pass.

**Infra:**

```bash
cd ~/mosip/automating-mosip-deployment/terraform/mosip_deployment/infra
terraform init
terraform plan -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars
```

**MOSIP services:**

```bash
cd ../mosip
terraform init
terraform plan -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars
```

**Verify:** all pods Running/Completed; `curl https://{MOSIP_DOMAIN}` → MOSIP landing page.

---

## Troubleshooting

### Long-running MOSIP modules

Re-running `terraform apply` is safe — Terraform reconciles failed Helm releases.

Before interrupting a module stuck at `Still creating... [20m+]`, inspect pods:

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --all-containers
```

If pods are healthy but Helm timed out, you can mark the release upgraded (use the **exact chart version from tfvars**):

```bash
helm upgrade regproc-reprocess mosip/regproc-reprocess -n regproc --reuse-values --version <chart-version-from-tfvars>
```

### Chart repository or network timeouts

Examples: `could not download chart`, `context deadline exceeded`, `failed get OpenAPI spec`.

Check from the deployment node:

```bash
helm repo update
kubectl get nodes
kubectl get pods -A
```

Re-run the same `terraform apply` when connectivity is restored.

For layer-specific failure maps, see [TROUBLESHOOTING.mdc](../../.cursor/rules/TROUBLESHOOTING.mdc) in the repository root.
