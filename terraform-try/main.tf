# Setting up the network infrastructure ----
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0" #limiting to major 6.x releases
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

#Defining the VPC
resource "aws_vpc" "main_network" {
  cidr_block = "10.0.0.0/16"
  #Enabling DNS access for high availability in case of ip change
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "AWS-project-VPC"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
  Name = "AWS-project-VPC"
  }
}

#Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_network.id
  tags = {
    Name = "AWS-project-IGW"
  Name = "AWS-project-IGW"
  }
}

#Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_network.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  vpc_id = aws_vpc.main_network.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true #Gives all IPs automatically
  tags = {
    Name = "AWS-project-Public-Subnet"
  }
}

#Route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "AWS-project-Public-RT"
  }
}

#Table association with subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#Security Groups Part ----
#Nginx SG
resource "aws_security_group" "nginx_bastion_sg" {
  name        = "nginx-bastion-sg"
  description = "Allow inbound HTTP/HTTPS and SSH from anywhere"
  vpc_id      = aws_vpc.main_network.id
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#Security Groups Part:
#Nginx SG
resource "aws_security_group" "nginx_bastion_sg" {
  name = "nginx-bastion-sg"
  description = "Allow inbound HTTP/HTTPS and SSH from anywhere"
  vpc_id = aws_vpc.main_network.id
  ingress {
    description = "HTTP from Internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from Admin and CD pipeline"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] #using 0.0.0.0/0 for now
  }
}

#Internal App and DB SG
resource "aws_security_group" "internal_sg" {
  name        = "internal-app-db-sg"
  description = "Allow inbound traddic only from Nginc bastion SG"
  vpc_id      = aws_vpc.main_network.id
  ingress {
    description     = "Allow all traffic from bastion host"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  name = "internal-app-db-sg"
  description = "Allow inbound traddic only from Nginc bastion SG"
  vpc_id = aws_vpc.main_network.id
  ingress {
    description = "Allow all traffic from bastion host"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.nginx_bastion_sg.id]
  }
  egress {
    description = "Allow all outbound traffic for internet access (e.g. OS updates)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Configuring EC2 Instances ----
#Ubuntu ami (for the EC2 instances)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#Nginx instance
resource "aws_instance" "nginx_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx_bastion_sg.id]
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name = "AWS-project-Nginx"
  }
}

#Node.js app instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.internal_sg.id]
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name = "AWS-project-App-Node"
  }
}

#Mysql Instance
resource "aws_instance" "nodejs_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.internal_sg.id]
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name = "AWS-project-Mysql"
  }
}







    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
