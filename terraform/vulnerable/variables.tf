variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS deployment region"
}

variable "environment" {
  type        = string
  default     = "lab-insecure"
  description = "Environment identifier"
}
