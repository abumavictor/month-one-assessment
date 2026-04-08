
# 1. Provider configuration
provider "aws" {
  region = var.aws_region
}

# Dynamic AMI Data Source for Amazon Linux 2 (Instructor Requirement)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 2. VPC
resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "techcorp-vpc" }
}

# 3. Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet-2" }
}

# 4. Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "techcorp-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "techcorp-private-subnet-2" }
}

# 5. Gateways
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp_vpc.id
  tags   = { Name = "techcorp-igw" }
}

resource "aws_eip" "nat_eip" {
  count  = 2
  domain = "vpc"
  tags = {
    Name = "techcorp-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = count.index == 0 ? aws_subnet.public_1.id : aws_subnet.public_2.id
  tags = {
    Name = "techcorp-nat-gw-${count.index + 1}"
  }
}

# 6. Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "techcorp-public-rt" }
}

resource "aws_route_table" "private_rt" {
  count  = 2
  vpc_id = aws_vpc.techcorp_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
  tags = { Name = "techcorp-private-rt-${count.index + 1}" }
}

# 7. Route Table Associations
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt[0].id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt[1].id
}

# 8. Security Groups
resource "aws_security_group" "bastion_sg" {
  name        = "techcorp-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "SSH from my current IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-bastion-sg" }
}

resource "aws_security_group" "alb_sg" {
  name        = "techcorp-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
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

  tags = { Name = "techcorp-alb-sg" }
}

resource "aws_security_group" "web_sg" {
  name        = "techcorp-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-web-sg" }
}

resource "aws_security_group" "db_sg" {
  name        = "techcorp-db-sg"
  description = "Security group for database server"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description     = "Postgres from Web Servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "Postgres from Bastion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-db-sg" }
}

# 9. Web Servers
resource "aws_instance" "web_server_1" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("user_data/web_server_setup.sh")
  tags                   = { Name = "techcorp-web-server-1" }
}

resource "aws_instance" "web_server_2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("user_data/web_server_setup.sh")
  tags                   = { Name = "techcorp-web-server-2" }
}

# 10. Database Server
resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  user_data              = file("user_data/db_server_setup.sh")
  tags                   = { Name = "techcorp-db-server" }
}

# 11. Bastion Host
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              echo "ec2-user:TechCorp2026!" | chpasswd
              sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
              systemctl restart sshd
              EOF

  tags = { Name = "techcorp-bastion" }
}

# 12. Application Load Balancer
resource "aws_lb" "techcorp_alb" {
  name               = "techcorp-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id
  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.techcorp_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}
vagrant@ubuntu2004:~/month-one-assessment$
