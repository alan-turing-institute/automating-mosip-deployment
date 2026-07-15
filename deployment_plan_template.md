# MOSIP deployment

> **Reference Documentation**: This deployment guide provides step-by-step instructions for deploying MOSIP. For comprehensive information about hardware requirements, network architecture, certificate requirements, and other prerequisites, please refer to the official MOSIP documentation at [https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites](https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites). The official documentation contains detailed specifications for VM sizing, network requirements, DNS configuration, and certificate management that should be reviewed before beginning deployment.

## Introduction

This document is the working deployment plan for installing MOSIP 1.2.1.1 with the Turing automation framework. Replace placeholder values (domain, IPs, paths) with your environment details.

The repository is an automation framework for the MOSIP deployment process. It uses the same MOSIP Helm charts and chart repositories as the official MOSIP deployment flow. It does not modify MOSIP application code, patch MOSIP modules, or replace MOSIP's own chart logic. The purpose of this framework is to make the official deployment process more repeatable, easier to verify, and easier to re-run when a step needs to be repeated.

## How this guide is organised

Follow these phases in order:

1. **Deployment node** — create the operator VM, connect it to the MOSIP network, install tools, clone this repository.
2. **Infrastructure path** — choose **AWS** (Terraform base infra) or **on-prem** (you provision VMs, DNS, and certificates).
3. **Shared deployment** — the same Ansible and Terraform sequence for both paths: inventory → WireGuard → OBS RKE2 cluster → main RKE2 cluster → MOSIP Terraform.

All commands in phases 2 and 3 are run **from the deployment node**.

---

## Phase 1 — Deployment node (start here)

### Why the deployment node comes first

Every Ansible playbook, Terraform apply, Helm operation, and `kubectl` check in this automation is designed to run from a dedicated **deployment node**. This machine is not a MOSIP application node; it is the control point that:

- Can SSHs to every WireGuard, Nginx, observation, and MOSIP cluster node.
- Holds the repository checkout, inventories, Terraform variables, kubeconfig files, and the SSH key Ansible uses.
- Talks to the Kubernetes API repeatedly while Helm releases and MOSIP modules become healthy.

**Why network placement matters:** Ansible copies scripts and configuration to remote hosts. Terraform and Helm poll the Kubernetes API while waiting for pods. If the deployment node reaches the cluster over a high-latency path, a VPN-only route, or an unstable link, you are more likely to see SSH drops, chart download failures, and API timeouts — especially during the longer MOSIP Terraform stage.

**Recommended setup:** put the deployment node on the **same private network** as the MOSIP and observation VMs. You may keep one interface or route for operator/admin access (SSH to the deployment node from your laptop) and a second interface or route into the MOSIP private network. WireGuard is for day-to-day admin access to the environment; avoid running the main install from a laptop over WireGuard when a co-located deployment node is available.

You may power off the deployment node after installation and use it again for day-two operations (Terraform variable changes, Ansible re-runs, upgrades).

### Step 1 — Create the deployment node VM

| Item | Value |
| --- | --- |
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
3. After running AWS base Terraform (see below), a second network interface is attached to the deployment node automatically; you must then configure it — see [Phase 2 → Access to MOSIP network](#access-to-mosip-network).
4. From the deployment node, verify SSH to private IPs of all provisioned nodes before starting Ansible.

Use private IPs from `terraform output` when filling Ansible inventories after AWS apply.

#### Option B — On-prem deployment

1. Create all infrastructure VMs yourself (see [On-prem prerequisites](#option-b--on-prem-prerequisites) for sizing and roles).
2. Place the deployment node on the **same internal/private network** as those VMs.
3. If the deployment node also needs access from a separate admin network, configure routing so admin SSH works without breaking reachability to MOSIP private IPs.

**Multi-interface example** (both options — admin network + MOSIP network). Interface names (`ens3`, `ens4`) are illustrative:

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

### Step 3 — Configure SSH access from the deployment node

Copy your SSH private key to the deployment node so Ansible can reach all other hosts without prompts. `<key-to-connect-to-deployment-node>` and `<ssh-private-key>` are normally **the same key**: the one key pair used to provision every VM in AWS Terraform (`ssh_key_name` in `terraform/aws/aws.tfvars` — see [Terraform apply](#terraform-apply) below) is what you use to reach the deployment node itself, and it is then copied onto the deployment node so Ansible can use it against every other host too:

```bash
scp -i <key-to-connect-to-deployment-node> <ssh-private-key> ubuntu@<deployment-node-ip>:~/.ssh/id_ed25519
ssh ubuntu@<deployment-node-ip>
chmod 600 ~/.ssh/id_ed25519
```

Use the default name `id_ed25519` so Ansible picks it up automatically (`ansible_ssh_private_key_file` in inventory).

### Step 4 — Install deployment tools

Clusters use **RKE2** (Ansible installs it on nodes — no `rke` binary on the deployment node). Install **istioctl 1.22.0** to match the Istio version deployed with the main cluster.

On deployment node:

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
git clone https://github.com/alan-turing-institute/automating-mosip-deployment.git
cd automating-mosip-deployment
```

---

## Phase 2 — Choose your infrastructure path

|  | Option A — AWS | Option B — On-prem |
| --- | --- | --- |
| Who creates VMs | Terraform `terraform/aws` (except deployment node) | You (OpenStack, VMware, bare metal, etc.) |
| DNS | Optional Route53 automation in Terraform | Manual (or your DNS team) |
| Deployment node network | Added to private VPC during the deployment | Same internal network as cluster VMs |
| Then | Continue to [Phase 3](#phase-3--shared-deployment-sequence) | Continue to [Phase 3](#phase-3--shared-deployment-sequence) |

Define **`{MOSIP_DOMAIN}`** once (e.g. `mosip.example.com` or `sandbox.example.org`) and use it throughout both paths.

---

### Option A — AWS base infrastructure

Run this stage only for AWS deployments. Terraform here is **declarative infrastructure only** — host configuration and RKE2 bootstrap remain in Ansible (Phase 3).

**Optional:** enable Route53 DNS in `aws.tfvars` — see [Optional AWS DNS](#optional-aws-dns-and-certbot).

#### Configure AWS credentials
You need working aws credentials on deployment node.
```
mkdir ~/.aws
vim ~/.aws/credentials #Copy your temporary access code from AWS Console under [default]
```

#### Optional AWS DNS

In `terraform/aws/aws.tfvars`:

- **DNS:** `enable_route53_records = true`, `cluster_env_domain`, `route53_zone_id`
- **Root domain:** `enable_root_domain_record = true`, `root_domain_record_type = "A"`

When DNS automation is enabled, Route53 records include A records for `api`, `api-internal`, OBS hosts, and CNAMEs for MOSIP service hostnames (see previous MOSIP DNS table for the full list).

#### Terraform apply
Change directory `cd ~/automating-mosip-deployment/terraform/aws`

Copy `.tmp` file `cp aws.tfvars.tmp aws.tfvars`

Edit file `aws.tfvars` and change `ssh_key_name`

```bash
terraform init
terraform plan -var-file=aws.tfvars
terraform apply -var-file=aws.tfvars
terraform output -json > aws-base-outputs.json
```

#### Access to MOSIP network
After the terraform apply, your deployment node VM has a 2nd interface added. AWS DHCP assigns it an IP automatically — you do not need to configure the address itself. What you need to fix is the **gateway/routing**: cloud-init's default config routes all traffic (`0.0.0.0/0`) through this new interface via a separate policy-routing table, which conflicts with your admin/primary interface's default route.

Find the new interface's MAC address first — run `ip -br link` (or check the AWS console → Network interfaces) and identify the interface that already has a DHCP-assigned IP but isn't your original admin interface.

Update deployment node netplan `sudo vim /etc/netplan/50-cloud-init.yaml`. AWS cloud-init writes the interface's config automatically after the second NIC is attached — it will look like the **"Before"** block below, with full-tunnel `use-routes: true` and a policy-routing table. Edit it down to the **"After"** block: set `use-routes: false` and replace the routes list with a single route scoped to the MOSIP private CIDR, so only MOSIP-private traffic uses this interface's gateway. Once edited, run `sudo netplan apply`.

```bash
# Before — AWS cloud-init default (routes everything through this interface, table 101)
    enX1:
      match:
        macaddress: "0a:83:6b:95:10:ed"  # replace with your interface's actual MAC
      dhcp4: true
      dhcp4-overrides:
        use-routes: true
        route-metric: 200
      dhcp6: false
      set-name: "enX1"
      routes:
      - table: 101
        to: "0.0.0.0/0"
        via: "10.100.3.1"
      - scope: "link"
        table: 101
        to: "10.100.3.0/24"
      routing-policy:
      - table: 101
        from: "10.100.3.104"

# After — edited to only route the MOSIP private CIDR over this interface
    enX1:
      match:
        macaddress: "0a:83:6b:95:10:ed"  # same MAC as above
      dhcp4: true
      dhcp4-overrides:
        use-routes: false
        route-metric: 200
      dhcp6: false
      set-name: "enX1"
      routes:
      - to: "10.100.0.0/16"
        via: "10.100.3.1"
```

#### Map AWS outputs to Ansible / Terraform templates

Use `aws-base-outputs.json` to populate existing files:

`rancher.ini` has three separate "obs"-adjacent names — don't guess which is which:

- `mosip_obs` — the OBS **RKE2/Rancher cluster node itself** (`obs-node-1`), running Rancher/Longhorn/monitoring.
- `nginx` — the **MOSIP-side** Nginx (`nginx-node-1`), public front door for `api.{MOSIP_DOMAIN}`.
- `nginx_obs` — a **separate** Nginx (`nginx-obs-node-1`) fronting the OBS cluster's Rancher/Keycloak UI at `rancher.{MOSIP_DOMAIN}` — not part of the `mosip_obs` cluster itself.

| Target file | Field/group to set | AWS output source |
| --- | --- | --- |
| `ansible/wireguard/inventory/hosts.ini` | `ansible_host` | `jumpserver_private_ip` |
| `ansible/wireguard/inventory/hosts.ini` | `wireguard_endpoint` | `jumpserver_public_ip` |
| `ansible/infra_deployment/inventory/rancher.ini` | `[physical_vms]`, `[control_plane_primary]`, `[control_plane_subsequent]` `ansible_host` | `physical_vm_private_ips` (map `vm1`..`vm6`) |
| `ansible/infra_deployment/inventory/rancher.ini` | `[mosip_obs]` `ansible_host` (`obs-node-1`) | `obs_private_ip` |
| `ansible/infra_deployment/inventory/rancher.ini` | `[nginx]` `ansible_host` (`nginx-node-1`) | `nginx_private_ip` |
| `ansible/infra_deployment/inventory/rancher.ini` | `[nginx_obs]` `ansible_host` (`nginx-obs-node-1`) | `nginx_obs_private_ip` |
| `ansible/infra_deployment/inventory/group_vars/all.yml` | `mosip_domain` | your chosen `{MOSIP_DOMAIN}` |
| `ansible/infra_deployment/inventory/group_vars/all.yml` | `nginx_obs_public_domain_names` | `rancher.{MOSIP_DOMAIN}` (served by the `nginx_obs` host above) |
| `ansible/infra_deployment/inventory/group_vars/all.yml` | `rancher_import_url` (later) | Rancher import URL, copied after the OBS Terraform stage |
| `terraform/obs_deployment/terraform.tfvars` | `rancher_hostname`, `kubeconfig_path` | `rancher.{MOSIP_DOMAIN}`; OBS kubeconfig path (`/home/ubuntu/rancher/obs/kube_config_cluster.yml`) |
| `terraform/mosip_deployment/terraform.tfvars` | `installation_domain`, `kubeconfig_path` | `{MOSIP_DOMAIN}`; Main kubeconfig path (`/home/ubuntu/rancher/mosip/kube_config_cluster.yml`) |

If you split control-plane/etcd/worker roles across dedicated nodes instead of the default colocated topology, the `control_plane_node_ips`, `etcd_node_ips`, and `worker_node_ips` outputs map onto `[control_plane_primary]`/`[control_plane_subsequent]`, `[rke2_etcd]`, and `[rke2_agents]`/`[worker_nodes]` respectively.

**After AWS apply:** confirm the deployment node can `ssh ubuntu@<private-ip>` to every node. If not, fix Step 2 (second interface / routing) before Phase 3.

---

### Option B — On-prem prerequisites

For on-prem, you create all resources listed below before Phase 3. The deployment node should already be on the internal network (Phase 1, Step 2, Option B).

#### Domain and DNS

Configure DNS for `{MOSIP_DOMAIN}`. Replace IPs with your infrastructure:


| **Record Type** | **Domain Name** | **IP/DNS** | **Purpose** |
| --- | --- | --- | --- |
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



#### VMs to create

Cluster nodes: Ubuntu 24.04 LTS per [official MOSIP docs](https://docs.mosip.io/1.2.0/setup/deploymentnew/v3-installation/1.2.0.2/pre-requisites) until 26.04 is validated for cluster nodes.

| VM | Count | vCPU | RAM | Disk | Network |
| --- | --- | --- | --- | --- | --- |
| deployment-node | 1 | 2 | 4 GB | 20 GB | Internal (+ admin access as needed) — **Phase 1** |
| wg-bastion | 1 | 2 | 4 GB | 8 GB | Internal + WireGuard public IP |
| mosip-nginx | 1 | 2 | 4 GB | 16 GB | Internal + public API IP |
| observation-node | 1 | 2 | 8 GB | 32 GB | Internal |
| mosip-node | 6 | 12 | 32 GB | 128 GB each | Internal |


## Phase 2 — Certificates
For AWS make sure your `.aws/credentials` are not expired.

For manual DNS, you may need two TXT records with different values — both are allowed; do not remove the first before validation completes.


```sh
# AWS route53
mkdir -p ~/cert/{config,work,logs}
certbot -v certonly --dns-route53 --agree-tos --preferred-challenges=dns \
--config-dir ~/cert/config --work-dir ~/cert/work --logs-dir ~/cert/logs \
  -d *.{MOSIP_DOMAIN} -d {MOSIP_DOMAIN}

# On Prem syntax
#
mkdir -p ~/cert/{config,work,logs}
certbot -v certonly --manual --agree-tos --preferred-challenges=dns \
--config-dir ~/cert/config --work-dir ~/cert/work --logs-dir ~/cert/logs \
  -d *.{MOSIP_DOMAIN} -d {MOSIP_DOMAIN}
```

Place wildcard cert as `fullchain.pem` and `privkey.pem` in `playbooks/roles/nginx_obs/files/` and `playbooks/roles/nginx/files/`, example base on `turing-mosip2.net` certificate.

```sh
# OBS
cp /home/ubuntu/cert/config/live/turing-mosip2.net/fullchain.pem ~/automating-mosip-deployment/ansible/infra_deployment/playbooks/roles/nginx_obs/files/
cp /home/ubuntu/cert/config/live/turing-mosip2.net/privkey.pem ~/automating-mosip-deployment/ansible/infra_deployment/playbooks/roles/nginx_obs/files/

# MOSIP
cp /home/ubuntu/cert/config/live/turing-mosip2.net/fullchain.pem ~/automating-mosip-deployment/ansible/infra_deployment/playbooks/roles/nginx/files/
cp /home/ubuntu/cert/config/live/turing-mosip2.net/privkey.pem ~/automating-mosip-deployment/ansible/infra_deployment/playbooks/roles/nginx/files/
```

---

## Phase 3 — Shared deployment sequence

Run all steps below **from the deployment node** after Phase 1 is complete and Phase 2 (AWS or on-prem) has provided VMs, DNS, and certificates.

### Prepare Ansible inventory

**Examples and field names are in the `*.tmp` files, make sure you copy `.tmp` and do not edit the `.tmp` file directly.**

#### WireGuard

Change directory `cd ~/automating-mosip-deployment/ansible/wireguard/inventory/`

Make copy from .tmp file `cp hosts.ini.tmp hosts.ini`

Edit File: `hosts.ini`


```sh
[wireguard]
wireguard-node ansible_host=<public_ip>  wireguard_endpoint=<public_ip>
```

#### Infra (RKE2)

Change directory `cd ~/automating-mosip-deployment/ansible/infra_deployment/inventory/`

Make copy from .tmp file `cp rancher.ini.tmp rancher.ini`

Edit File: `rancher.ini`


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

...
[mosip_obs]
obs-node-1 ansible_host=<observation-node-private-ip>

[nginx]
nginx-node-1 ansible_host=<mosip-nginx-private-ip>

[nginx_obs]
nginx-obs-node-1 ansible_host=<obs-nginx-private-ip>
```

Topology default: vm1 = primary control plane; vm2–vm3 = HA control plane; vm1–vm6 = worker agents.

**RKE2 group_vars**

Change directory `group_vars/`

Make copy from .tmp file `cp all.yml.tmp all.yml`

Edit File: `all.yml`

Mandatory changes: `mosip_domain`, `nginx_obs_public_domain_names`

```sh
mosip_domain: "turing-mosip.net"  # MOSIP Domain/Subdomain Root

nginx_obs_public_domain_names: "rancher.turing-mosip.net" # Rancher DNS
```

### Prepare Terraform inventory
#### Terraform OBS inventory

Change directory `cd ~/automating-mosip-deployment/terraform/obs_deployment`

Make from .tmp file `cp terraform.tfvars.tmp terraform.tfvars`

Edit File: `terraform.tfvars` update rancher_hostname to match your DNS

#### Terraform MOSIP inventory

Change directory `cd ~/automating-mosip-deployment/terraform/mosip_deployment`

Make from .tmp file `cp terraform.tfvars.tmp terraform.tfvars`

Edit File: `terraform.tfvars` update `installation_name` and `installation_domain`

### Update all nodes

```bash
cd ~/automating-mosip-deployment/ansible/infra_deployment
ansible-playbook -f 12 -v -i inventory/rancher.ini playbooks/apt-upgrade.yml
```

### WireGuard deployment

- Ensure WireGuard public IP is on `wg-bastion`; port `51820/udp` open.
- From deployment node:

```bash
cd ~/automating-mosip-deployment/ansible/wireguard
ansible-playbook -v -i inventory/hosts.ini playbooks/wireguard.yml
```

- Fetch peer config: `ssh ubuntu@<wg-bastion-public-ip> "sudo cat /root/wireguard/config/peer1/peer1.conf"`
- Default MTU in peer configs: **1330** (adjust only if your network requires it).
- Save the fetched config on your laptop before starting the tunnel — `wg-quick` reads it from `/etc/wireguard/<name>.conf`:

```bash
sudo mkdir -p /etc/wireguard
sudo vi /etc/wireguard/wg1-mosip.conf # paste the fetched peer1.conf contents
sudo chmod 600 /etc/wireguard/wg1-mosip.conf
```

- Test from laptop:

```bash
sudo systemctl start wg-quick@wg1-mosip
ssh ubuntu@<any-internal-host-ip>
```

### kubectl access and kubeconfig locations

Both RKE2 clusters (OBS and Main) are deployed via Ansible, and each deployment writes its kubeconfig to **two places** on the deployment node:

- **Explicit path** — this is the same path you set as `kubeconfig_path` in Terraform tfvars, and it always points at that specific cluster regardless of deployment order:
  - OBS: `/home/ubuntu/rancher/obs/kube_config_cluster.yml`
  - Main: `/home/ubuntu/rancher/mosip/kube_config_cluster.yml`
- **Default path** — `~/.kube/config`, copied there by the same Ansible step so plain `kubectl` commands work with no `--kubeconfig` flag.

In this guide's sequence, Main is deployed after OBS — so once you reach the Main cluster stage, `kubectl get pods -A` (no flags) talks to **Main**, and reaching OBS again requires `kubectl --kubeconfig=/home/ubuntu/rancher/obs/kube_config_cluster.yml <cmd>` When in doubt about which cluster is currently the default, use the explicit path for the cluster you actually want.

### Observation node (RKE2 + Rancher stack)

- Run Ansible
```bash
cd ~/automating-mosip-deployment/ansible/infra_deployment
ansible-playbook -v -i inventory/rancher.ini playbooks/deploy-rancher-obs.yml
```

**Verify:** `kubectl get pods -A` (OBS is the only cluster deployed so far, so this targets OBS via `~/.kube/config`); `curl https://rancher.{MOSIP_DOMAIN}` → 502 until Terraform OBS apply.

**Terraform OBS:**

```bash
cd ~/automating-mosip-deployment/terraform/obs_deployment
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

**Verify:** Rancher UI loads; copy import URL from Rancher → **Import Existing → Generic** → paste into `rancher_import_url` in `~/automating-mosip-deployment/ansible/infra_deployment/inventory/group_vars/all.yml`.

### Main cluster (RKE2 + Istio)

```bash
cd ~/automating-mosip-deployment/ansible/infra_deployment
ansible-playbook -f 8 -v -i inventory/rancher.ini playbooks/deploy-all.yml
```

**Verify:** `kubectl get pods -A` (now targets **Main** by default)

### MOSIP Terraform (infra then services)

**Expect long runtimes** — first apply often takes about an hour. Modules deploy sequentially; `config-server` and `regproc` may need 15–30 minutes before probes pass.

**Infra:**

```bash
cd ~/automating-mosip-deployment/terraform/mosip_deployment/infra
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

Examples: `could not download chart`, `context deadline exceeded`, `failed get OpenAPI spec`. Most likely your deployment node is undersized and `terraform` sub-processes are crashing. It could also be network routing problem. Investigate them in that order.

Check from the deployment node:

```bash
helm repo update
kubectl get nodes
kubectl get pods -A
```

Re-run the same `terraform apply` when connectivity is restored.
