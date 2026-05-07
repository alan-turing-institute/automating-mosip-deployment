resource "aws_vpc" "main" {
  cidr_block           = var.network_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name        = var.network_name
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.network_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

data "aws_key_pair" "selected" {
  key_name = var.ssh_key_name
}

locals {
  worker_effective_count = min(var.worker_count, var.physical_vm_count)

  physical_vm_keys = [for i in range(var.physical_vm_count) : "vm${i + 1}"]

  physical_vm_map = {
    for idx, key in local.physical_vm_keys :
    key => {
      index = idx
    }
  }

  control_plane_node_ips = [
    for i in range(min(var.control_plane_count, var.physical_vm_count)) :
    aws_instance.physical_vm["vm${i + 1}"].private_ip
  ]

  etcd_node_ips = [
    for i in range(min(var.etcd_count, var.physical_vm_count)) :
    aws_instance.physical_vm["vm${i + 1}"].private_ip
  ]

  worker_node_ips = [
    for i in range(local.worker_effective_count) :
    aws_instance.physical_vm["vm${i + 1}"].private_ip
  ]
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.network_name}-public-subnet-${count.index + 1}"
    Type        = "Public"
    Environment = var.environment
    Project     = var.project_name
    AZ          = var.availability_zones[count.index % length(var.availability_zones)]
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name        = "${var.network_name}-private-subnet-${count.index + 1}"
    Type        = "Private"
    Environment = var.environment
    Project     = var.project_name
    AZ          = var.availability_zones[count.index % length(var.availability_zones)]
  }
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  domain = "vpc"

  tags = {
    Name        = "${var.network_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.network_name}-nat-gateway-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.network_name}-public-rt"
    Type        = "Public"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
  }

  tags = {
    Name        = "${var.network_name}-private-rt-${count.index + 1}"
    Type        = "Private"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index % length(aws_route_table.private)].id
}

resource "aws_security_group" "jumpserver" {
  name        = "${var.jumpserver_name}-sg"
  description = "Security group for jumpserver"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "WireGuard VPN access"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS web traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.jumpserver_name}-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "k8s_nodes" {
  name        = "${var.project_name}-k8s-nodes-sg"
  description = "Security group for control/etcd/worker nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "SSH from WireGuard clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.wireguard_cidr]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "RKE2 supervisor"
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "Canal VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "Etcd client/peer/metrics"
    from_port   = 2379
    to_port     = 2381
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-k8s-nodes-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-nginx-sg"
  description = "Security group for MOSIP nginx node"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Internal service ports"
    from_port   = 5432
    to_port     = 61616
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-nginx-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# OBS: RKE1 cluster nodes. Port set aligned with MOSIP k8s-infra
# k8-cluster/on-prem/rke1/ports.yaml (plus VPC-scoped SSH from WireGuard CIDR).
resource "aws_security_group" "obs" {
  name        = "${var.project_name}-obs-sg"
  description = "Security group for OBS RKE1 cluster nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "SSH from WireGuard clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.wireguard_cidr]
  }

  # ports.yaml: HTTP/HTTPS on cluster nodes (scoped to VPC)
  ingress {
    description = "HTTP (RKE1 / Rancher node requirements)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "HTTPS (RKE1 / Rancher node requirements)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "Kubernetes API (RKE1)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  # ports.yaml: Docker daemon (RKE SSH provisioning)
  ingress {
    description = "Docker daemon (RKE1)"
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  # ports.yaml: etcd client and peer (Rancher/RKE reference range)
  ingress {
    description = "Etcd client/peer (RKE1)"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  # ports.yaml: kubelet / scheduler / controller-manager
  ingress {
    description = "Kubelet and control plane component ports (10250-10252)"
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "Kube-proxy health / metrics (RKE1 ports.yaml: 10256)"
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "RKE1 ports.yaml: 9796"
    from_port   = 9796
    to_port     = 9796
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "RKE1 ports.yaml: 10254"
    from_port   = 10254
    to_port     = 10254
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  # ports.yaml: VXLAN (Rancher AWS SG reference); Canal also uses 8472 below
  ingress {
    description = "Overlay VXLAN UDP (4789)"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "Canal VXLAN UDP (8472)"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "NodePort TCP range (includes Istio/public ingress 30080 etc.)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "NodePort UDP range (ports.yaml)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "udp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "MINIO NodePort (ports.yaml example)"
    from_port   = 30900
    to_port     = 30900
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-obs-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "nginx_obs" {
  name        = "${var.project_name}-nginx-obs-sg"
  description = "Security group for OBS nginx node"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.network_cidr]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-nginx-obs-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_instance" "jumpserver" {
  ami                         = var.jumpserver_ami_id
  instance_type               = var.jumpserver_instance_type
  key_name                    = data.aws_key_pair.selected.key_name
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.jumpserver.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 64
    delete_on_termination = true
  }

  tags = {
    Name        = var.jumpserver_name
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_instance" "physical_vm" {
  for_each = local.physical_vm_map

  ami                         = var.node_ami_id
  instance_type               = var.k8s_instance_type
  key_name                    = data.aws_key_pair.selected.key_name
  subnet_id                   = aws_subnet.private[each.value.index % length(aws_subnet.private)].id
  vpc_security_group_ids      = [aws_security_group.k8s_nodes.id]
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 128
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Environment = var.environment
    Project     = var.project_name
    Role        = "physical_vm"
  }
}

resource "aws_instance" "obs_node" {
  ami                         = var.node_ami_id
  instance_type               = var.obs_instance_type
  key_name                    = data.aws_key_pair.selected.key_name
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.obs.id]
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 64
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-obs-node-1"
    Environment = var.environment
    Project     = var.project_name
    Role        = "mosip_obs"
  }
}

resource "aws_instance" "nginx_node" {
  ami                         = var.node_ami_id
  instance_type               = var.nginx_instance_type
  key_name                    = data.aws_key_pair.selected.key_name
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.nginx.id]
  associate_public_ip_address = true
  iam_instance_profile        = var.enable_certbot_iam_profile ? aws_iam_instance_profile.certbot_profile[0].name : null

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 64
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-nginx-node-1"
    Environment = var.environment
    Project     = var.project_name
    Role        = "nginx"
  }
}

resource "aws_instance" "nginx_obs_node" {
  ami                         = var.node_ami_id
  instance_type               = var.nginx_obs_instance_type
  key_name                    = data.aws_key_pair.selected.key_name
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.nginx_obs.id]
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 32
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-nginx-obs-node-1"
    Environment = var.environment
    Project     = var.project_name
    Role        = "nginx_obs"
  }
}

resource "aws_iam_role" "certbot_role" {
  count = var.enable_certbot_iam_profile ? 1 : 0

  name = "${var.project_name}-${var.environment}-certbot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "certbot_route53" {
  count = var.enable_certbot_iam_profile ? 1 : 0

  name = "${var.project_name}-${var.environment}-certbot-route53"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:GetChange"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "certbot_policy_attachment" {
  count = var.enable_certbot_iam_profile ? 1 : 0

  role       = aws_iam_role.certbot_role[0].name
  policy_arn = aws_iam_policy.certbot_route53[0].arn
}

resource "aws_iam_instance_profile" "certbot_profile" {
  count = var.enable_certbot_iam_profile ? 1 : 0

  name = "${var.project_name}-${var.environment}-certbot-profile"
  role = aws_iam_role.certbot_role[0].name
}

data "aws_route53_zone" "selected" {
  count = (
    var.enable_route53_records &&
    trimspace(var.route53_zone_id) == "" &&
    trimspace(var.route53_zone_name) != ""
  ) ? 1 : 0

  name         = trimsuffix(var.route53_zone_name, ".")
  private_zone = false
}

locals {
  route53_target_zone_id = trimspace(var.route53_zone_id) != "" ? var.route53_zone_id : (
    length(data.aws_route53_zone.selected) > 0 ? data.aws_route53_zone.selected[0].zone_id : ""
  )

  route53_api_records = var.enable_route53_records ? {
    "api" = {
      name    = "api.${var.cluster_env_domain}"
      type    = "A"
      ttl     = 300
      records = [aws_instance.nginx_node.public_ip]
    }
    "api-internal" = {
      name    = "api-internal.${var.cluster_env_domain}"
      type    = "A"
      ttl     = 300
      records = [aws_instance.nginx_node.private_ip]
    }
  } : {}

  route53_obs_a_records = var.enable_route53_records ? {
    for sub in var.subdomain_obs_a_records : "obs-${sub}" => {
      name    = "${sub}.${var.cluster_env_domain}"
      type    = "A"
      ttl     = 300
      records = [aws_instance.nginx_obs_node.private_ip]
    }
  } : {}

  route53_public_records = var.enable_route53_records ? {
    for sub in var.subdomain_public : "public-${sub}" => {
      name    = "${sub}.${var.cluster_env_domain}"
      type    = "CNAME"
      ttl     = 300
      records = ["api.${var.cluster_env_domain}"]
    }
  } : {}

  route53_internal_records = var.enable_route53_records ? {
    for sub in var.subdomain_internal : "internal-${sub}" => {
      name    = "${sub}.${var.cluster_env_domain}"
      type    = "CNAME"
      ttl     = 300
      records = ["api-internal.${var.cluster_env_domain}"]
    }
  } : {}

  route53_root_record = var.enable_route53_records && var.enable_root_domain_record ? {
    "root-domain" = {
      name = var.cluster_env_domain
      type = var.root_domain_record_type
      ttl  = 300
      # Landing page stays internal/admin-only: same private target as api-internal.
      records = [aws_instance.nginx_node.private_ip]
    }
  } : {}

  route53_records = merge(
    local.route53_api_records,
    local.route53_obs_a_records,
    local.route53_public_records,
    local.route53_internal_records,
    local.route53_root_record
  )
}

resource "aws_route53_record" "cluster_dns" {
  for_each = var.enable_route53_records ? local.route53_records : {}

  zone_id = local.route53_target_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}

resource "aws_eip" "jumpserver" {
  count = var.create_jumpserver_eip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.jumpserver.id

  tags = {
    Name        = "${var.jumpserver_name}-eip"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}
