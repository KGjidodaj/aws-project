#Defining the VPC
#tfsec:ignore:require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "main_network" {
  cidr_block = "10.0.0.0/16"
  #Enabling DNS access for high availability in case of ip change
  enable_dns_support   = true
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
  }
}

#Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_network.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  #tfsec:ignore:no-public-ip-subnet
  map_public_ip_on_launch = true #Gives all IPs automatically
  tags = {
    Name = "AWS-project-Public-Subnet"
  }
}

#App subnet
resource "aws_subnet" "app_subnet" {
  vpc_id                  = aws_vpc.main_network.id
  cidr_block              = "10.0.2.0/24" #splitting cidr_block 10.0.2.0/24 for the app subnet
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "AWS-project-app-Subnet"
  }
}

#Mysql subnet
resource "aws_subnet" "mysql_subnet" {
  vpc_id                  = aws_vpc.main_network.id
  cidr_block              = "10.0.3.0/24" #splitting cidr_block 10.0.3.0/24 for the mysql subnet
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "AWS-project-mysql-Subnet"
  }
}

#Route table (public)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id #Using the internet gateway for the nginx public intance opposed to the other instances
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

#Nat Gateway elastic IP
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "AWS-project-NAT-EIP"
  }
}

#NAT Gateway setup
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.igw] #Can cause errors if igw is not created first
  tags = {
    Name = "AWS-project-NAT_Gateway"
  }
}

#App Route table
resource "aws_route_table" "app_rt" {
  vpc_id = aws_vpc.main_network.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "AWS-project-App-RT"
  }
}

#Route table association (app)
resource "aws_route_table_association" "app_rt_assoc" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.app_rt.id
}

#Mysql Route Table
resource "aws_route_table" "mysql_rt" {
  vpc_id = aws_vpc.main_network.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "AWS-project-Mysql-RT"
  }
}

#Route table association (mysql)
resource "aws_route_table_association" "mysql_rt_assoc" {
  subnet_id      = aws_subnet.mysql_subnet.id
  route_table_id = aws_route_table.mysql_rt.id
}

#Security Groups Part:
#Nginx SG (Tier 1)
resource "aws_security_group" "nginx_bastion_sg" {
  name        = "nginx-bastion-sg"
  description = "Allow inbound HTTP/HTTPS and SSH from anywhere"
  vpc_id      = aws_vpc.main_network.id
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from Admin and CD pipeline"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #trivy:ignore:AVD-AWS-0107
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"] #Using this cidr block since this project is using a ci/cd pipeline and all github servers are ephemeral from different ips
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#App SG (Tier 2)
resource "aws_security_group" "app_sg" {
  name        = "app-tier-sg"
  description = "Allow inbound only from nginx"
  vpc_id      = aws_vpc.main_network.id
  ingress {
    description = "HTTP from nginx to kubernetes node port"
    # Using the nodeport specified in the manifests
    from_port       = 30000
    to_port         = 30000
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_bastion_sg.id]
  }
  ingress {
    description     = "ssh for ansible deployment"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_bastion_sg.id] #Allowing an ssh connection only from the nginx-bastion-prox
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#DB SG (Tier 3)
resource "aws_security_group" "db_sg" {
  name        = "db-tier-sg"
  description = "Allow traffic only from the app instance"
  vpc_id      = aws_vpc.main_network.id
  ingress {
    description     = "Mysql traffic from the app node"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  ingress {
    description     = "ssh for ansible"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_bastion_sg.id] #Allowing an ssh connection only from the nginx-bastion-proxy
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:no-public-egress-sgr
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
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"] #Using one of the newest images
  }
  filter {
    name = "virtualization-type"
    #Using hvm instead of the legacy PV to run with the variable specified instance types
    values = ["hvm"]
  }
}

#Nginx instance
resource "aws_instance" "nginx_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  metadata_options {
    http_tokens = "required" #IMDSv2 required
  }
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx_bastion_sg.id]
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name = "AWS-project-Nginx"
  }
}
resource "aws_eip" "nginx_eip" {
  instance   = aws_instance.nginx_server.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw] #Depend on the internet gateway to be created for potential errors
  tags = {
    Name = "AWS-project-nginx-EIP"
  }
}
#Node.js app instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  metadata_options {
    http_tokens = "required"
  }
  subnet_id              = aws_subnet.app_subnet.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name = "AWS-project-App-Node"
  }
}

#Mysql Instance
resource "aws_instance" "mysql_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  metadata_options {
    http_tokens = "required"
  }
  subnet_id              = aws_subnet.mysql_subnet.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name = "AWS-project-Mysql"
  }
}
