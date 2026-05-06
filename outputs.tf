# 1. VPC ID
output "vpc_id" {
  description = "The ID of the TechCorp VPC"
  value       = aws_vpc.main.id
}

# 2. Application Load Balancer DNS Name
output "alb_dns_name" {
  description = "The DNS name of the Load Balancer to access the website"
  value       = aws_lb.web_alb.dns_name
}

# 3. Bastion Host Public IP
output "bastion_public_ip" {
  description = "The public IP address of the Bastion Host"
  value       = aws_eip.bastion_eip.public_ip
}

# Optional extra output for your NAT Gateways (matching your previous intent)
output "nat_gateway_ips" {
  description = "The public IP addresses of the NAT Gateways"
  value       = [aws_eip.nat_1.public_ip, aws_eip.nat_2.public_ip]
}