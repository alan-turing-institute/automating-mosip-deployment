variable "aws_region" {
  description = "AWS region for base infrastructure resources"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC"
  type        = string
}

variable "network_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the NAT Gateway subnet (no EC2 instances — exists solely to give the NAT GW an IGW route)"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the single private subnet (all MOSIP nodes)"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone used for both subnets"
  type        = string
}

variable "environment" {
  description = "Environment tag value"
  type        = string
}

variable "project_name" {
  description = "Project tag value"
  type        = string
}

variable "jumpserver_name" {
  description = "Name tag for jumpserver instance"
  type        = string
}

variable "ssh_key_name" {
  description = "AWS EC2 key pair name used by all provisioned EC2 instances (jumpserver, physical_vms, obs, nginx, nginx_obs)"
  type        = string

  validation {
    condition = (
      trimspace(var.ssh_key_name) != "" &&
      var.ssh_key_name != "replace-with-your-keypair-name"
    )
    error_message = "ssh_key_name must be set to a real AWS EC2 key pair name (not empty and not the placeholder)."
  }
}

variable "enable_deployment_node_private_eni" {
  description = "Create a network interface in the private subnet and attach it to an existing deployment node EC2 instance"
  type        = bool
  default     = true
}

variable "deployment_node_instance_id" {
  description = "EC2 instance ID of the pre-provisioned deployment node (required when enable_deployment_node_private_eni=true)"
  type        = string
  default     = ""

  validation {
    condition = (
      !var.enable_deployment_node_private_eni ||
      trimspace(var.deployment_node_instance_id) != ""
    )
    error_message = "deployment_node_instance_id must be set when enable_deployment_node_private_eni=true, or set enable_deployment_node_private_eni=false to skip."
  }
}

variable "jumpserver_instance_type" {
  description = "Jumpserver EC2 instance type"
  type        = string
  default     = "t3a.2xlarge"
}

variable "jumpserver_ami_id" {
  description = "AMI ID used for jumpserver EC2 instance"
  type        = string
}

variable "create_jumpserver_eip" {
  description = "Create and attach Elastic IP to jumpserver"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnet outbound internet access"
  type        = bool
  default     = true
}

variable "wireguard_cidr" {
  description = "CIDR range used by WireGuard clients for access"
  type        = string
  default     = "10.13.13.0/24"
}

variable "node_ami_id" {
  description = "AMI used for MOSIP/OBS/NGINX EC2 instances"
  type        = string
}

variable "k8s_instance_type" {
  description = "Instance type for Rancher control/etcd/worker nodes"
  type        = string
  default     = "t3a.2xlarge"
}

variable "nginx_instance_type" {
  description = "Instance type for MOSIP nginx node"
  type        = string
  default     = "t3a.2xlarge"
}

variable "obs_instance_type" {
  description = "Instance type for OBS node"
  type        = string
  default     = "t3a.2xlarge"
}

variable "nginx_obs_instance_type" {
  description = "Instance type for OBS nginx node"
  type        = string
  default     = "t3a.2xlarge"
}

variable "control_plane_count" {
  description = "Number of control plane nodes in physical_vms"
  type        = number
  default     = 3
}

variable "etcd_count" {
  description = "Number of etcd nodes in physical_vms"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes in physical_vms"
  type        = number
  default     = 6
}

variable "physical_vm_count" {
  description = "Number of physical_vms entries for Rancher inventory"
  type        = number
  default     = 6
}

variable "enable_route53_records" {
  description = "Enable Route53 DNS record automation"
  type        = bool
  default     = false
}

variable "cluster_env_domain" {
  description = "Full deployment domain used for records (can include subdomain), e.g. warwick-1.turing-mosip.net"
  type        = string
  default     = ""

  validation {
    condition = (
      !var.enable_route53_records ||
      trimspace(var.cluster_env_domain) != ""
    )
    error_message = "cluster_env_domain is required when enable_route53_records=true."
  }
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID where records are created (parent zone, e.g. turing-mosip.net)"
  type        = string
  default     = ""

  validation {
    condition = (
      !var.enable_route53_records ||
      (
        (trimspace(var.route53_zone_id) != "" && trimspace(var.route53_zone_name) == "") ||
        (trimspace(var.route53_zone_id) == "" && trimspace(var.route53_zone_name) != "")
      )
    )
    error_message = "When enable_route53_records=true, set exactly one of route53_zone_id or route53_zone_name."
  }

  validation {
    condition = (
      trimspace(var.route53_zone_id) == "" ||
      var.route53_zone_id != "Z0123456789EXAMPLE"
    )
    error_message = "route53_zone_id cannot use template placeholder value."
  }
}

variable "route53_zone_name" {
  description = "Route53 hosted zone DNS name where records are created (parent zone), e.g. turing-mosip.net"
  type        = string
  default     = ""
}

variable "subdomain_public" {
  description = "Public CNAME subdomains pointing to api domain"
  type        = list(string)
  default     = ["prereg", "resident", "idp", "admin"]
}

variable "subdomain_internal" {
  description = "Internal CNAME subdomains pointing to api-internal domain"
  type        = list(string)
  default = [
    "activemq",
    "kibana",
    "regclient",
    "object-store",
    "kafka",
    "iam",
    "postgres",
    "pmp",
    "onboarder",
    "smtp",
    "minio",
    "esignet",
    "healthservices",
    "signup",
  ]
}

variable "enable_certbot_iam_profile" {
  description = "Enable certbot Route53 IAM role/profile attachment on nginx node"
  type        = bool
  default     = false
}

variable "subdomain_obs_a_records" {
  description = "OBS A record subdomains pointing to nginx_obs private IP"
  type        = list(string)
  default     = ["rancher", "rancher-keycloak"]
}

variable "enable_root_domain_record" {
  description = "Create root domain A record for cluster_env_domain (admin-only landing page via internal target)"
  type        = bool
  default     = true

  validation {
    condition = (
      !var.enable_route53_records ||
      var.enable_root_domain_record
    )
    error_message = "enable_root_domain_record must be true when enable_route53_records=true."
  }
}

variable "root_domain_record_type" {
  description = "Record type for root domain when enabled. For this project it must always be A."
  type        = string
  default     = "A"

  validation {
    condition     = var.root_domain_record_type == "A"
    error_message = "root_domain_record_type must be A (CNAME at apex is not supported in this project)."
  }
}
