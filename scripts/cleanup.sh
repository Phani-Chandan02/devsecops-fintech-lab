#!/usr/bin/env bash
set -e

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FORENSIC_BUCKET="fintech-devsecops-forensics-${ACCOUNT_ID}"
PIPELINE_BUCKET="fintech-codepipeline-artifacts-${ACCOUNT_ID}"

echo "=========================================================="
echo " TEARDOWN: CLEANING UP LAB RESOURCES IN $REGION"
echo "=========================================================="

echo "[1/8] Removing EventBridge Rule & Targets..."
aws events remove-targets --rule guardduty-runtime-response --ids "1" --region "$REGION" 2>/dev/null || true
aws events delete-rule --name guardduty-runtime-response --region "$REGION" 2>/dev/null || true

echo "[2/8] Removing Lambda Functions..."
aws lambda delete-function --function-name fintech-runtime-soar --region "$REGION" 2>/dev/null || true
aws lambda delete-function --function-name fintech-secret-rotation --region "$REGION" 2>/dev/null || true

echo "[3/8] Removing Secrets Manager Secret..."
aws secretsmanager delete-secret --secret-id fintech/payment-api --force-delete-without-recovery --region "$REGION" 2>/dev/null || true

echo "[4/8] Removing Network Firewall & Rules..."
aws network-firewall delete-firewall --firewall-name devsecops-lab-network-firewall --region "$REGION" 2>/dev/null || true
aws network-firewall delete-firewall-policy --firewall-policy-name fintech-firewall-policy --region "$REGION" 2>/dev/null || true
aws network-firewall delete-rule-group --rule-group-name fintech-domain-deny-group --type STATEFUL --region "$REGION" 2>/dev/null || true
aws network-firewall delete-rule-group --rule-group-name fintech-ip-drop-group --type STATEFUL --region "$REGION" 2>/dev/null || true

echo "[5/8] Removing Prefix List..."
PL_ID=$(aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=devsecops-threat-ips" --query "PrefixLists[0].PrefixListId" --output text --region "$REGION" 2>/dev/null || echo "None")
if [ "$PL_ID" != "None" ] && [ -n "$PL_ID" ]; then
  aws ec2 delete-managed-prefix-list --prefix-list-id "$PL_ID" --region "$REGION" 2>/dev/null || true
fi

echo "[6/8] Removing ECS Resources..."
aws ecs delete-cluster --cluster fintech-devsecops-cluster --region "$REGION" 2>/dev/null || true

echo "[7/8] Removing S3 Forensic & Artifact Buckets..."
if aws s3api head-bucket --bucket "$FORENSIC_BUCKET" 2>/dev/null; then
  aws s3 rm "s3://$FORENSIC_BUCKET" --recursive 2>/dev/null || true
  aws s3 rb "s3://$FORENSIC_BUCKET" --region "$REGION" 2>/dev/null || true
fi

if aws s3api head-bucket --bucket "$PIPELINE_BUCKET" 2>/dev/null; then
  aws s3 rm "s3://$PIPELINE_BUCKET" --recursive 2>/dev/null || true
  aws s3 rb "s3://$PIPELINE_BUCKET" --region "$REGION" 2>/dev/null || true
fi

echo "[8/8] Terminating Runtime EC2 Node..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=devsecops-runtime" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --region "$REGION" 2>/dev/null || echo "None")
if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION" 2>/dev/null || true
fi

echo "[+] Lab teardown completed. Verify billing console."
