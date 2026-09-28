terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

# ------------------------------------------------------------------------------
# Almacenamiento S3
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "sre_backups" {
  bucket        = "sre-system-backups-local"
  force_destroy = true

  tags = {
    Name        = "SRE Backups Local"
    Environment = "Dev"
  }
}

# ------------------------------------------------------------------------------
# Red Principal (VPC y Subred)
# ------------------------------------------------------------------------------
resource "aws_vpc" "sre_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "sre-lab-vpc"
    Environment = "Dev"
  }
}

resource "aws_subnet" "sre_subnet" {
  vpc_id            = aws_vpc.sre_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "sre-lab-subnet-public"
    Environment = "Dev"
  }
}

# ------------------------------------------------------------------------------
# Grupo de Seguridad (Firewall)
# ------------------------------------------------------------------------------
resource "aws_security_group" "sre_sg" {
  name        = "sre-web-sg"
  description = "Permitir tráfico SSH y HTTP entrante"
  vpc_id      = aws_vpc.sre_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sre-web-security-group"
  }
}

# ------------------------------------------------------------------------------
# Instancia EC2 Simulada con UserData (Servidor Web)
# ------------------------------------------------------------------------------
resource "aws_instance" "sre_web_server" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sre_subnet.id
  vpc_security_group_ids = [aws_security_group.sre_sg.id]

  user_data_base64            = base64encode(<<-EOF
                                #!/bin/bash
                                echo "=== Starting SRE Lab Web Server Deployment ==="
                                yum update -y
                                yum install -y nginx
                                systemctl enable nginx
                                systemctl start nginx
                                echo "<h1>SRE/DevOps Lab - LocalStack & Terraform Stack</h1><p>Environment: Dev | Server: Active</p>" > /usr/share/nginx/html/index.html
                                echo "=== Web Server Configuration Completed ==="
                                EOF
  )
  user_data_replace_on_change = true

  tags = {
    Name        = "sre-web-server"
    Environment = "Dev"
  }
}