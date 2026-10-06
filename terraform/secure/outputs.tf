output "secure_bucket_id" {
  value       = aws_s3_bucket.secure_storage.id
  description = "Identifier of the secure encrypted S3 bucket"
}

output "secure_sg_id" {
  value       = aws_security_group.secure_sg.id
  description = "Identifier of the hardened security group"
}

output "secret_arn" {
  value       = data.aws_secretsmanager_secret.payment_api_secret.arn
  description = "ARN of the Secrets Manager secret for secure retrieval"
}
