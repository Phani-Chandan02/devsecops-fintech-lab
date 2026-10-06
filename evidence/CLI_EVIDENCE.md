# CLI Evidence Collection Script & Query Guide

Run these commands in PowerShell or CloudShell to collect JSON/text evidence for your submission report:

## AWS Identity & Setup
```bash
aws sts get-caller-identity
aws configure list
```

## Phase 1 Evidence
```bash
# Checkov scan on vulnerable Terraform
checkov -d terraform/vulnerable --framework terraform --output cli

# Secret scan output
detect-secrets scan terraform/vulnerable/ --all-files

# CodeBuild build status
aws codebuild batch-get-builds --ids $(aws codebuild list-builds-for-project --project-name fintech-devsecops-phase1 --query "ids[0]" --output text)

# Secrets Manager configuration
aws secretsmanager describe-secret --secret-id fintech/payment-api
aws secretsmanager get-secret-value --secret-id fintech/payment-api

# Secret Rotation Lambda
aws lambda get-function --function-name fintech-secret-rotation
```

## Phase 2 Evidence
```bash
# ECR Repository details
aws ecr describe-repositories --repository-names payment-api

# ECR Enhanced Scanning configuration
aws ecr get-registry-scanning-configuration

# Image scan findings (Severity counts)
aws ecr describe-image-scan-findings --repository-name payment-api --image-id imageTag=latest --query "imageScanFindings.findingSeverityCounts"

# Inspector v2 findings list
aws inspector2 list-findings --filter-criteria '{"ecrImageRepositoryName":[{"comparison":"EQUALS","value":"payment-api"}]}'

# ECS Cluster & Service status
aws ecs describe-clusters --clusters fintech-devsecops-cluster
aws ecs describe-services --cluster fintech-devsecops-cluster --services payment-api-service
```

## Phase 3 Evidence
```bash
# VPC Subnets & Inspection Subnet
aws ec2 describe-subnets --filters "Name=tag:Project,Values=devsecops-fintech-lab"

# Customer Managed Prefix List
aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=devsecops-threat-ips"

# Network Firewall status & endpoints
aws network-firewall describe-firewall --firewall-name devsecops-lab-network-firewall
aws network-firewall describe-firewall-policy --firewall-policy-name fintech-firewall-policy

# SSM Managed Node Information
aws ssm describe-instance-information --query "InstanceInformationList[*].[InstanceId,PingStatus,PlatformName,AgentVersion]"

# Patch Baseline definition
aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=PCI-DSS-LAB-Baseline"

# Patch Compliance scan invocation & results
aws ssm list-command-invocations --details --query "CommandInvocations[*].[CommandId,DocumentName,Status]"
```

## Phase 4 Evidence
```bash
# GuardDuty Detector
aws guardduty list-detectors

# EventBridge Rule & Targets
aws events describe-rule --name guardduty-runtime-response
aws events list-targets-by-rule --rule guardduty-runtime-response

# SOAR Lambda Function
aws lambda get-function --function-name fintech-runtime-soar

# Systems Manager Run Command history
aws ssm list-commands --filters "Key=DocumentName,Values=AWS-RunShellScript"

# S3 Forensic Bucket Encryption & Public Block
aws s3api get-bucket-encryption --bucket fintech-devsecops-forensics-435023701114
aws s3api get-public-access-block --bucket fintech-devsecops-forensics-435023701114

# Forensic Evidence Files in S3
aws s3 ls s3://fintech-devsecops-forensics-435023701114/incidents/ --recursive

# EC2 Instance Security Group (Quarantined)
aws ec2 describe-instances --filters "Name=tag:Name,Values=devsecops-runtime" --query "Reservations[0].Instances[0].SecurityGroups[*].[GroupId,GroupName]"
```
