provider "aws" {
  region = var.region
  access_key = var.secrets.aws_access_key_id
  secret_key = var.secrets.aws_secret_access_key
  default_tags {
    tags = {
      Name = "guac"
    }
  }
}

data "aws_ami" "latest-rhe8" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-8*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_subnet" "public" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false
}

resource "aws_security_group" "allow_app" {
  name        = "APP_SECURITY_GROUP"
  description = "Allow APP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "APP Access"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "SSH_SECURITY_GROUP"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public_ec2" {
  ami                    = data.aws_ami.latest-rhe8.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_app.id]
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public.id
  user_data = file("./userdata.sh")
  root_block_device {
    volume_size = 50
  }
}

output "instance_ip_addr" {
  value = aws_instance.public_ec2.public_ip
}
