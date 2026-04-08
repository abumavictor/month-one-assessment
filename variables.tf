variable "aws_region" {
  description = "The AWS region to deploy in"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "my_ip" {
  description = "Your local IP address for Bastion SSH access"
  type        = string
  default     = "105.127.17.81/32"
}

variable "instance_type_web" {
  description = "The instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "techcorp-key"
}
