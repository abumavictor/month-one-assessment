provider "aws" {
  region = var.aws_region
}

# 1. AMI Data Source (Requirement 5: Amazon Linux 2)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 2. Virtual Private Cloud (Requirement 1)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "techcorp-vpc" }
}

# 3. Internet Gateway (Requirement 3)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "techcorp-igw" }
}

# 4. Subnets (Requirement 2: Two AZs)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet-2" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "techcorp-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "techcorp-private-subnet-2" }
}

# 5. NAT Gateways (Requirement 3: One in each public subnet)
resource "aws_eip" "nat_1" {}
resource "aws_eip" "nat_2" {}

resource "aws_nat_gateway" "gw_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "techcorp-nat-gateway-1" }
}

resource "aws_nat_gateway" "gw_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id
  tags          = { Name = "techcorp-nat-gateway-2" }
}

# Route Tables & Associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "techcorp-public-route-table" }
}

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw_1.id
  }
  tags = { Name = "techcorp-private-route-table-1" }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw_2.id
  }
  tags = { Name = "techcorp-private-route-table-2" }
}

resource "aws_route_table_association" "priv_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "priv_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

# 6. Security Groups (Requirement 4)
resource "aws_security_group" "bastion_sg" {
  name   = "techcorp-bastion-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Requirement: Current IP only
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
  description = "Allow HTTP and HTTPS to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
  name   = "techcorp-web-sg"
  vpc_id = aws_vpc.main.id

  # Requirement: Allow HTTP from ALB Security Group only
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  # Requirement: Allow SSH from Bastion SG
  ingress {
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
  name   = "techcorp-db-sg"
  vpc_id = aws_vpc.main.id
  # Requirement: Allow Postgres only from web security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  # Requirement: Allow SSH from Bastion SG
  ingress {
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

# 7. EC2 Instances (Requirement 5)
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = { Name = "techcorp-bastion" }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id # Requirement: Associate Elastic IP
  tags     = { Name = "techcorp-bastion-eip" }
}

resource "aws_instance" "web_1" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("${path.module}/user_data/web_server_setup.sh")
  tags = { Name = "techcorp-web-1" }
}

resource "aws_instance" "web_2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_2.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("${path.module}/user_data/web_server_setup.sh")
  tags = { Name = "techcorp-web-2" }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_name
  user_data              = file("${path.module}/user_data/db_server_setup.sh")
  tags = { Name = "techcorp-db" }
}

# 8. Application Load Balancer (Requirement 6)
resource "aws_lb" "web_alb" {
  name               = "techcorp-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags               = { Name = "techcorp-web-alb" }
}

# 9. ALB Target Group (Requirement 6)
resource "aws_lb_target_group" "web_tg" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-499"
  }
  tags = { Name = "techcorp-web-tg" }
}

# ALB Listener (Requirement 6)
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ALB Target Group Attachment (Requirement 6)
resource "aws_lb_target_group_attachment" "web_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}