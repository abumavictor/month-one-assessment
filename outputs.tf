output "vpc_id" {
  value = aws_vpc.techcorp_vpc.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "nat_gateway_ips" {
  value       = aws_eip.nat_eip[*].public_ip
  description = "The public IP addresses of the NAT Gateways"
}

output "alb_dns_name" {
  value       = aws_lb.techcorp_alb.dns_name
  description = "The DNS name of the load balancer to access the website"
}

output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "The public IP address of the bastion host"
}
