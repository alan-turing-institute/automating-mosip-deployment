output "network_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "jumpserver_id" {
  description = "ID of the jumpserver instance"
  value       = aws_instance.jumpserver.id
}

output "jumpserver_public_ip" {
  description = "Public IP of jumpserver"
  value       = var.create_jumpserver_eip ? aws_eip.jumpserver[0].public_ip : aws_instance.jumpserver.public_ip
}

output "jumpserver_private_ip" {
  description = "Private IP of jumpserver"
  value       = aws_instance.jumpserver.private_ip
}

output "jumpserver_security_group_id" {
  description = "Security group ID used by jumpserver"
  value       = aws_security_group.jumpserver.id
}

output "cloud_specific" {
  description = "AWS-specific identifiers used by later stages"
  value = {
    vpc_id                 = aws_vpc.main.id
    vpc_cidr               = aws_vpc.main.cidr_block
    internet_gateway_id    = aws_internet_gateway.main.id
    nat_gateway_id         = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
    public_route_table_id  = aws_route_table.public.id
    private_route_table_id = var.enable_nat_gateway ? aws_route_table.private[0].id : null
    jumpserver_id          = aws_instance.jumpserver.id
    jumpserver_public_ip   = var.create_jumpserver_eip ? aws_eip.jumpserver[0].public_ip : aws_instance.jumpserver.public_ip
    jumpserver_private_ip  = aws_instance.jumpserver.private_ip
    nginx_public_ip        = aws_instance.nginx_node.public_ip
    nginx_private_ip       = aws_instance.nginx_node.private_ip
    obs_private_ip         = aws_instance.obs_node.private_ip
    nginx_obs_private_ip   = aws_instance.nginx_obs_node.private_ip
  }
}

output "physical_vm_private_ips" {
  description = "Map of physical_vms private IPs (vm1..vmN)"
  value       = { for key, instance in aws_instance.physical_vm : key => instance.private_ip }
}

output "control_plane_node_ips" {
  description = "Private IPs for control plane nodes (mapped from first N physical_vms)"
  value       = local.control_plane_node_ips
}

output "etcd_node_ips" {
  description = "Private IPs for etcd nodes (mapped from first N physical_vms)"
  value       = local.etcd_node_ips
}

output "worker_node_ips" {
  description = "Private IPs for worker nodes (mapped from first N physical_vms)"
  value       = local.worker_node_ips
}

output "nginx_private_ip" {
  description = "Private IP for nginx-node-1 inventory host"
  value       = aws_instance.nginx_node.private_ip
}

output "nginx_public_ip" {
  description = "Public IP for nginx-node-1"
  value       = aws_instance.nginx_node.public_ip
}

output "obs_private_ip" {
  description = "Private IP for obs-node-1 inventory host"
  value       = aws_instance.obs_node.private_ip
}

output "nginx_obs_private_ip" {
  description = "Private IP for nginx-obs-node-1 inventory host"
  value       = aws_instance.nginx_obs_node.private_ip
}

output "route53_records_created" {
  description = "Route53 records created when enable_route53_records=true"
  value       = var.enable_route53_records ? { for key, record in aws_route53_record.cluster_dns : key => record.fqdn } : {}
}

output "certbot_instance_profile_name" {
  description = "Certbot IAM instance profile attached to nginx node when enabled"
  value       = var.enable_certbot_iam_profile ? aws_iam_instance_profile.certbot_profile[0].name : null
}
