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
- Optional certbot IAM role/policy/profile for nginx node

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
cd terraform/aws/base-infra
cp aws.tfvars.tmp aws.tfvars
terraform init
terraform plan -var-file=aws.tfvars
terraform apply -var-file=aws.tfvars
terraform output -json > aws-base-outputs.json
```

## Output Mapping to Existing Files

Use module outputs to populate existing files, without changing file structure:

- `jumpserver_private_ip` -> `ansible/wireguard/inventory/hosts.ini` `ansible_host`
- `jumpserver_public_ip` -> `ansible/wireguard/inventory/hosts.ini` `wireguard_endpoint`
- `physical_vm_private_ips.vm1..vm6` -> `ansible/infra_deployment/inventory/rancher.ini` `[physical_vms]` `ansible_host`
- `control_plane_node_ips` -> `rancher.ini` `[control_plane_nodes]` `node_ip`
- `etcd_node_ips` -> `rancher.ini` `[etcd_nodes]` `node_ip`
- `worker_node_ips` -> `rancher.ini` `[worker_nodes]` `node_ip`
- `obs_private_ip` -> `rancher.ini` `[mosip_obs]` `ansible_host`
- `nginx_private_ip` -> `rancher.ini` `[nginx]` `ansible_host`
- `nginx_obs_private_ip` -> `rancher.ini` `[nginx_obs]` `ansible_host`
- `network_id`, `public_subnet_ids`, `private_subnet_ids`, `cloud_specific` -> AWS network identifiers for checks/automation
- `route53_records_created` -> audit of optional DNS automation
- `certbot_instance_profile_name` -> audit of optional certbot IAM/profile attachment

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

## Optional Certbot IAM/Profile

Set `enable_certbot_iam_profile=true` to create and attach:
- IAM role for EC2
- Route53 update policy for certbot DNS challenge flows
- Instance profile attached to `nginx-node-1`
