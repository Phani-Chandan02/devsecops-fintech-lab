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

# 1. Secure S3 Bucket with PCI-DSS v4.0 aligned controls
resource "aws_s3_bucket" "secure_storage" {
  bucket        = "fintech-payment-records-${var.environment}"
  force_destroy = true

  tags = {
    Environment = var.environment
    Compliance  = "PCI-DSS-v4.0"
    Project     = "devsecops-fintech-lab"
  }
}

resource "aws_s3_bucket_public_access_block" "secure_storage_pab" {
  bucket                  = aws_s3_bucket.secure_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_storage_encryption" {
  bucket = aws_s3_bucket.secure_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "secure_storage_versioning" {
  bucket = aws_s3_bucket.secure_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Hardened Security Group: Ingress restricted to internal VPC HTTPS only
resource "aws_security_group" "secure_sg" {
  name        = "fintech-hardened-sg"
  description = "Hardened security group with restricted ingress"

  ingress {
    description = "TLS/HTTPS from internal VPC CIDR only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Restricted outbound TLS to internal services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Environment = var.environment
    Compliance  = "PCI-DSS-v4.0"
    Project     = "devsecops-fintech-lab"
  }
}

# 3. Secret retrieval via AWS Secrets Manager data source (Zero hardcoded credentials)
data "aws_secretsmanager_secret" "payment_api_secret" {
  name = "fintech/payment-api"
}
