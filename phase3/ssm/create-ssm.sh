#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ROLE_NAME="devsecops-ec2-ssm-role"
PROFILE_NAME="devsecops-ec2-profile"

echo "=== [1/4] Configuring IAM Role & Instance Profile for EC2 SSM ==="
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  sleep 5
fi

if ! aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" 2>/dev/null; then
  aws iam create-instance-profile --instance-profile-name "$PROFILE_NAME"
  aws iam add-role-to-instance-profile --instance-profile-name "$PROFILE_NAME" --role-name "$ROLE_NAME"
  sleep 5
fi

echo "=== [2/4] Creating Custom Patch Baseline: PCI-DSS-LAB-Baseline ==="
BASELINE_ID=$(aws ssm describe-patch-baselines \
  --filters "Key=NAME_PREFIX,Values=PCI-DSS-LAB-Baseline" \
  --query "BaselineIdentities[0].BaselineId" \
  --output text \
  --region "$REGION" 2>/dev/null || echo "None")

if [ "$BASELINE_ID" == "None" ] || [ -z "$BASELINE_ID" ]; then
  BASELINE_ID=$(aws ssm create-patch-baseline \
    --name "PCI-DSS-LAB-Baseline" \
    --operating-system "AMAZON_LINUX_2023" \
    --description "Lab baseline for PCI-DSS v4.0 patch compliance auditing" \
    --approval-rules "PatchRules=[{PatchFilterGroup={PatchFilters=[{Key=CLASSIFICATION,Values=[Security]},{Key=SEVERITY,Values=[Critical,Important]}]},ApproveAfterDays=0}]" \
    --query 'BaselineId' \
    --output text \
    --region "$REGION")
  echo "Created Patch Baseline: $BASELINE_ID"
else
  echo "Patch Baseline exists: $BASELINE_ID"
fi

echo "=== [3/4] Registering Patch Group PCI-LAB ==="
aws ssm register-patch-baseline-for-patch-group \
  --baseline-id "$BASELINE_ID" \
  --patch-group "PCI-LAB" \
  --region "$REGION" || true

echo "=== [4/4] Systems Manager Setup Ready ==="
