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
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3  = "http: //localhost:4566"
    ec2 = "http: //localhost:4566"
  }
  }

  # Almacenamiento S3

  resource "aws_s3_bucket" "sre_backups" {
  bucket = "sre-system-backups-local"

  tags = {
    Name        = "sre-backups"
    Environment = "Dev"
  }
  }

  # Red (VPC & Subnet)

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
  vpc_id                  = aws_vpc.sre_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
  Name        = "sre-lab-subnet-public"
  Environment = "Dev"
  }
  }

  #Seguridad (Security Group)

  resource "aws_security_group" "sre_sg" {
  name        = "sre-lab-web-sg"
  description = "Permitir trafico SSH e HTTP de entrada"
  vpc_id      = aws_vpc.sre_vpc.id

  ingress {
  description = "SSH access"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "HTTP access"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
  Name        = "sre-lab-sg"
  Environment = "Dev"
  }
  }

  #Cómputo (Instancia EC2)

  resource "aws_instance" "sre_web_server" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sre_subnet.id
  vpc_security_group_ids = [aws_security_group.sre_sg.id]

  tags = {
  Name        = "sre-web-server-local"
  Environment = "Dev"
  Role        = "WebServer"
  }
  }