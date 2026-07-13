# AWS Base Infrastructure Prerequisite

This Terraform module provisions only the AWS prerequisite infrastructure that must exist before running the current Ansible playbooks.

## Scope

In scope:
- VPC
- Public and private subnets
- Internet gateway
- Public/private route tables and associations
- Optional NAT gateway path
- Jumpserver security group
- Jumpserver EC2 instance
- Optional jumpserver EIP
- Rancher inventory compute instances (`physical_vms`, `mosip_obs`, `nginx`, `nginx_obs`)
- Security groups for k8s nodes, nginx, obs, nginx_obs
- Optional Route53 DNS records

Out of scope:
- Any changes to Ansible playbook logic
- MOSIP service deployment Terraform (`terraform/mosip_deployment`)
- OBS deployment Terraform (`terraform/obs_deployment`)
- WireGuard installation/configuration (already handled by `ansible/wireguard` playbooks)

## Usage

### Required Before Plan/Apply

- Ensure local AWS credentials are configured and working for the target account/region before running Terraform.
- Verify access first (example): `aws sts get-caller-identity`.
- Set `ssh_key_name` in `aws.tfvars` to a real EC2 key pair name that exists in `aws_region`.
- This key pair is used by **all** EC2 instances created by this module (not only jumpserver).
- If missing, placeholder, or not found in the selected region, Terraform will fail fast.
- If `enable_route53_records=true`, set:
  - `cluster_env_domain` to your full deployment domain (for example `warwick-1.turing-mosip.net`)
  - exactly one of:
    - `route53_zone_id` (explicit hosted zone ID), or
    - `route53_zone_name` (hosted zone DNS name, auto-resolve ID)
- Route53 hosted zones/domains are not created by this module; they must already exist.
- Clarification:
  - `cluster_env_domain` = full record suffix to create.
  - `route53_zone_name` = parent hosted zone where records are created (often `turing-mosip.net`).

```bash
cd terraform/aws
cp aws.tfvars.tmp aws.tfvars
terraform init
terraform plan -var-file=aws.tfvars
terraform apply -var-file=aws.tfvars
terraform output -json > aws-base-outputs.json
```

## Output Mapping to Existing Files

Use module outputs to populate existing files, without changing file structure. Group/host names below are the actual names in `ansible/infra_deployment/inventory/rancher.ini.tmp` — three different "obs"-adjacent names show up here and are easy to confuse:

- `mosip_obs` — the OBS **RKE2/Rancher cluster node itself** (`obs-node-1`), running the Rancher/Longhorn/monitoring stack.
- `nginx` — the **MOSIP-side** Nginx (`nginx-node-1`), the public front door for `api.{MOSIP_DOMAIN}`.
- `nginx_obs` — a **separate** Nginx (`nginx-obs-node-1`) that fronts the OBS cluster's Rancher/Keycloak UI at `rancher.{MOSIP_DOMAIN}` — it is not part of the `mosip_obs` cluster itself.

| Output | Target | Field/group |
| --- | --- | --- |
| `jumpserver_private_ip` | `ansible/wireguard/inventory/hosts.ini` | `ansible_host` |
| `jumpserver_public_ip` | `ansible/wireguard/inventory/hosts.ini` | `wireguard_endpoint` |
| `physical_vm_private_ips` (map `vm1`..`vm6`) | `ansible/infra_deployment/inventory/rancher.ini` | `[physical_vms]`, `[control_plane_primary]`, `[control_plane_subsequent]` `ansible_host` (default colocated topology — see `rancher.ini.tmp` comments) |
| `control_plane_node_ips`, `etcd_node_ips`, `worker_node_ips` | `rancher.ini` | Only relevant if you split control-plane/etcd/worker roles across dedicated nodes instead of the default colocated topology — map onto `[control_plane_primary]`/`[control_plane_subsequent]`, `[rke2_etcd]`, `[rke2_agents]`/`[worker_nodes]` respectively |
| `obs_private_ip` | `rancher.ini` | `[mosip_obs]` `ansible_host` (`obs-node-1`) |
| `nginx_private_ip` | `rancher.ini` | `[nginx]` `ansible_host` (`nginx-node-1`) |
| `nginx_obs_private_ip` | `rancher.ini` | `[nginx_obs]` `ansible_host` (`nginx-obs-node-1`) |
| `network_id`, `public_subnet_id`, `private_subnet_id`, `cloud_specific` | — | AWS network identifiers for checks/automation |
| `route53_records_created` | — | Audit of optional DNS automation |

Note:
- This base module does not install or configure WireGuard; run existing WireGuard Ansible playbooks.
- Continue using existing inventories and downstream flow after applying this prerequisite step.

## Optional DNS Automation Coverage

When `enable_route53_records=true`, this module can create:
- `api.<domain>` (A -> nginx public IP)
- `api-internal.<domain>` (A -> nginx private IP)
- OBS A records (default: `rancher.<domain>`, `rancher-keycloak.<domain>`) -> nginx_obs private IP
- Public CNAMEs (default: `prereg`, `resident`, `idp`, `admin`) -> `api.<domain>`
- Internal CNAMEs (default: `activemq`, `kibana`, `regclient`, `object-store`, `kafka`, `iam`, `postgres`, `pmp`, `onboarder`, `smtp`, `minio`, `esignet`, `healthservices`, `signup`) -> `api-internal.<domain>`
- Optional root-domain record via:
  - `enable_root_domain_record=true` (default)
  - `root_domain_record_type="A"` (required/default)

Note:
- Subdomain list values must be labels only, for example `signup` (not `signup.<domain>`), otherwise Terraform will generate duplicated FQDN suffixes.

## Certificates

This module does not provision any IAM role/profile for certbot. Issue certificates manually on the deployment node using the Route53 DNS plugin against the AWS credentials already configured there (`~/.aws/credentials`) — see [Optional AWS DNS and certbot](../../deployment_plan_template.md#optional-aws-dns-and-certbot) in the deployment plan.
