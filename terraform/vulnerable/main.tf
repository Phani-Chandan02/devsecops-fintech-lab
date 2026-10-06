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
  region = var.aws_region
}

# 1. Insecure S3 Bucket: No encryption, public read/write allowed
resource "aws_s3_bucket" "insecure_storage" {
  bucket        = "fintech-payment-records-${var.environment}"
  force_destroy = true

  tags = {
    Environment = var.environment
    Compliance  = "Non-Compliant"
  }
}

# 2. Insecure Security Group: Wide open ingress to 0.0.0.0/0
resource "aws_security_group" "insecure_sg" {
  name        = "fintech-open-sg"
  description = "Insecure security group with open ingress"

  ingress {
    description = "Open SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Unrestricted all traffic"
    from_port   = 0
    to_port     = 65535
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

# 3. Dummy Hardcoded Secret for detect-secrets demonstration (NOT a real key)
locals {
  database_master_password = "SuperSecretPassword123!_HardcodedLabDemo"
  api_gateway_secret_token = "DemoToken_VulnerableHardcodedValue_99182746"
}
