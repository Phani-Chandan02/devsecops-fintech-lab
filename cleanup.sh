#!/usr/bin/env bash
set -e
REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
echo "Review and delete these lab resources in $REGION:"
echo "- CodePipeline and CodeBuild projects"
echo "- ECR repository and ECS cluster/service/task"
echo "- Amazon Inspector ECR scanning (disable after deleting images if desired)"
echo "- Secrets Manager demo secret + rotation Lambda"
echo "- GuardDuty/EventBridge/SOAR Lambda"
echo "- SSM EC2 test instance and related security groups"
echo "- Network Firewall, firewall policy/rule groups, inspection subnet/routes"
echo "- NAT Gateway (if created), Elastic IPs, VPC resources"
echo "- Forensic S3 bucket and KMS key"
echo "Use the console for the Network Firewall/VPC stack to avoid orphaned routing resources."
