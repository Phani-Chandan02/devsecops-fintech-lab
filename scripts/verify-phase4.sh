#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FORENSIC_BUCKET="fintech-devsecops-forensics-${ACCOUNT_ID}"

echo "=== VERIFYING PHASE 4: Runtime Threat Remediation (SOAR) ==="

# 1. Verify Encrypted S3 Bucket
if aws s3api head-bucket --bucket "$FORENSIC_BUCKET" 2>/dev/null; then
  ALGO=$(aws s3api get-bucket-encryption --bucket "$FORENSIC_BUCKET" --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm" --output text 2>/dev/null || echo "None")
  echo "[PASS] Forensic S3 Bucket: '$FORENSIC_BUCKET' exists (Encryption: $ALGO)"
else
  echo "[FAIL] Forensic S3 Bucket: '$FORENSIC_BUCKET' not found"
fi

# 2. Verify Quarantine Security Group
Q_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=devsecops-quarantine-sg" --query "SecurityGroups[0].GroupId" --output text --region "$REGION" 2>/dev/null || echo "None")
if [ "$Q_SG" != "None" ] && [ -n "$Q_SG" ]; then
  echo "[PASS] Quarantine Security Group: '$Q_SG' active"
else
  echo "[FAIL] Quarantine Security Group not found"
fi

# 3. Verify GuardDuty Detector
DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" --query "DetectorIds[0]" --output text 2>/dev/null || echo "None")
if [ "$DETECTOR_ID" != "None" ] && [ -n "$DETECTOR_ID" ]; then
  echo "[PASS] Amazon GuardDuty: Active detector ($DETECTOR_ID)"
else
  echo "[FAIL] Amazon GuardDuty: No detector active in $REGION"
fi

# 4. Verify SOAR Lambda
if aws lambda get-function --function-name fintech-runtime-soar --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] SOAR Lambda: Function 'fintech-runtime-soar' configured"
else
  echo "[FAIL] SOAR Lambda: Function 'fintech-runtime-soar' not found"
fi

# 5. Verify EventBridge Rule
if aws events describe-rule --name guardduty-runtime-response --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] EventBridge Rule: 'guardduty-runtime-response' active"
else
  echo "[FAIL] EventBridge Rule: 'guardduty-runtime-response' not found"
fi
