output "insecure_bucket_id" {
  value       = aws_s3_bucket.insecure_storage.id
  description = "Identifier of the insecure S3 bucket"
}

output "insecure_sg_id" {
  value       = aws_security_group.insecure_sg.id
  description = "Identifier of the insecure security group"
}
