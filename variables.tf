variable "aws_region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "my_ip" {
  description = "Your local IP address for Bastion SSH access (Placeholder for security)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type_web" {
  description = "The instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "The instance type for the database server"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "your-key-name-here"
}
variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "techcorp-key"
}
