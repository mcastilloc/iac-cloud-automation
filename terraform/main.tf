terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor apuntando a LocalStack
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    vpc = "http://localhost:4566"
  }
}

# 1. Bucket S3 de Almacenamiento
resource "aws_s3_bucket" "sre_backups" {
  bucket = "sre-system-backups-local"
}

# 2. Red Virtual (VPC)
resource "aws_vpc" "sre_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "sre-lab-vpc"
    Environment = "Dev"
  }
}

# 3. Subred
resource "aws_subnet" "sre_subnet" {
  vpc_id            = aws_vpc.sre_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sre-lab-subnet"
  }
}