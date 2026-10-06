#!/usr/bin/env bash
set -e

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FORENSIC_BUCKET="phani-fintech-forensics-${ACCOUNT_ID}"
PIPELINE_BUCKET="phani-codepipeline-artifacts-${ACCOUNT_ID}"

echo "=========================================================="
echo " TEARDOWN: CLEANING UP LAB RESOURCES FOR PHANI ($REGION)"
echo "=========================================================="

echo "[1/11] Removing EventBridge Rule & Targets..."
aws events remove-targets --rule guardduty-runtime-response --ids "1" --region "$REGION" 2>/dev/null || true
aws events delete-rule --name guardduty-runtime-response --region "$REGION" 2>/dev/null || true

echo "[2/11] Removing Lambda Functions..."
aws lambda delete-function --function-name phani-runtime-soar --region "$REGION" 2>/dev/null || true
aws lambda delete-function --function-name phani-secret-rotation --region "$REGION" 2>/dev/null || true

echo "[3/11] Removing Secrets Manager Secret..."
aws secretsmanager delete-secret --secret-id phani/fintech/payment-api --force-delete-without-recovery --region "$REGION" 2>/dev/null || true

echo "[4/11] Removing Network Firewall Policy & Rule Groups..."
aws network-firewall delete-firewall-policy --firewall-policy-name phani-firewall-policy --region "$REGION" 2>/dev/null || true
aws network-firewall delete-rule-group --rule-group-name phani-domain-deny-group --type STATEFUL --region "$REGION" 2>/dev/null || true
aws network-firewall delete-rule-group --rule-group-name phani-ip-drop-group --type STATEFUL --region "$REGION" 2>/dev/null || true

echo "[5/11] Removing Prefix List..."
PL_ID=$(aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=phani-threat-ips" --query "PrefixLists[0].PrefixListId" --output text --region "$REGION" 2>/dev/null || echo "None")
if [ "$PL_ID" != "None" ] && [ -n "$PL_ID" ]; then
  aws ec2 delete-managed-prefix-list --prefix-list-id "$PL_ID" --region "$REGION" 2>/dev/null || true
fi

echo "[6/11] Removing ECS Service & Cluster..."
aws ecs update-service --cluster phani-devsecops-cluster --service payment-api-service --desired-count 0 --region "$REGION" 2>/dev/null || true
aws ecs delete-service --cluster phani-devsecops-cluster --service payment-api-service --force --region "$REGION" 2>/dev/null || true
aws ecs delete-cluster --cluster phani-devsecops-cluster --region "$REGION" 2>/dev/null || true

echo "[7/11] Terminating EC2 Runtime Instance..."
aws ec2 terminate-instances --instance-ids i-01ee2623ea4ae8598 --region "$REGION" 2>/dev/null || true

echo "[8/11] Removing CodePipeline & CodeBuild Projects..."
aws codepipeline delete-pipeline --name phani-devsecops-pipeline --region "$REGION" 2>/dev/null || true
aws codebuild delete-project --name phani-devsecops-phase1 --region "$REGION" 2>/dev/null || true
aws codebuild delete-project --name phani-devsecops-phase2 --region "$REGION" 2>/dev/null || true

echo "[9/11] Removing SSM Patch Baseline..."
PB_ID=$(aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=phani-PCI-DSS-LAB-Baseline" --query "BaselineIdentities[0].BaselineId" --output text --region "$REGION" 2>/dev/null || echo "None")
if [ "$PB_ID" != "None" ] && [ -n "$PB_ID" ]; then
  aws ssm delete-patch-baseline --baseline-id "$PB_ID" --region "$REGION" 2>/dev/null || true
fi

echo "[10/11] Cleaning up S3 Forensic & Pipeline Buckets..."
if aws s3api head-bucket --bucket "$FORENSIC_BUCKET" 2>/dev/null; then
  aws s3 rm "s3://$FORENSIC_BUCKET" --recursive 2>/dev/null || true
  aws s3 rb "s3://$FORENSIC_BUCKET" --region "$REGION" 2>/dev/null || true
fi

if aws s3api head-bucket --bucket "$PIPELINE_BUCKET" 2>/dev/null; then
  aws s3 rm "s3://$PIPELINE_BUCKET" --recursive 2>/dev/null || true
  aws s3 rb "s3://$PIPELINE_BUCKET" --region "$REGION" 2>/dev/null || true
fi

echo "[11/11] Teardown complete. Candidate phani lab resources cleanly decommissioned."
