terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

# Intentionally insecure demo resource: public S3 ACL + no encryption.
resource "aws_s3_bucket" "demo" {
  bucket = "devsecops-demo-${data.aws_caller_identity.current.account_id}"
}

resource "aws_security_group" "bad_sg" {
  name = "devsecops-bad-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_caller_identity" "current" {}

# Dummy example credential. This is NOT a real credential.
variable "demo_password" {
  default = "AKIAIOSFODNN7EXAMPLE"
}
