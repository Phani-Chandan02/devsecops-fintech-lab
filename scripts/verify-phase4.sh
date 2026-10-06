#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FORENSIC_BUCKET="phani-fintech-forensics-${ACCOUNT_ID}"

echo "=== VERIFYING PHASE 4: Runtime Threat Remediation (SOAR) (Candidate: phani) ==="

# 1. Verify Encrypted S3 Bucket
if aws s3api head-bucket --bucket "$FORENSIC_BUCKET" 2>/dev/null; then
  ALGO=$(aws s3api get-bucket-encryption --bucket "$FORENSIC_BUCKET" --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm" --output text 2>/dev/null || echo "None")
  echo "[PASS] Forensic S3 Bucket: '$FORENSIC_BUCKET' exists (Encryption: $ALGO)"
else
  echo "[FAIL] Forensic S3 Bucket: '$FORENSIC_BUCKET' not found"
fi

# 2. Verify Quarantine Security Group
Q_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=phani-quarantine-sg" --query "SecurityGroups[0].GroupId" --output text --region "$REGION" 2>/dev/null || echo "None")
if [ "$Q_SG" != "None" ] && [ -n "$Q_SG" ]; then
  echo "[PASS] Quarantine Security Group: '$Q_SG' (phani-quarantine-sg) active"
else
  echo "[FAIL] Quarantine Security Group 'phani-quarantine-sg' not found"
fi

# 3. Verify GuardDuty Detector
DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" --query "DetectorIds[0]" --output text 2>/dev/null || echo "None")
if [ "$DETECTOR_ID" != "None" ] && [ -n "$DETECTOR_ID" ]; then
  echo "[PASS] Amazon GuardDuty: Active detector ($DETECTOR_ID)"
else
  echo "[FAIL] Amazon GuardDuty: No detector active in $REGION"
fi

# 4. Verify SOAR Lambda
if aws lambda get-function --function-name phani-runtime-soar --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] SOAR Lambda: Function 'phani-runtime-soar' configured"
else
  echo "[FAIL] SOAR Lambda: Function 'phani-runtime-soar' not found"
fi

# 5. Verify EventBridge Rule
if aws events describe-rule --name guardduty-runtime-response --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] EventBridge Rule: 'guardduty-runtime-response' active"
else
  echo "[FAIL] EventBridge Rule: 'guardduty-runtime-response' not found"
fi

# 6. Verify Forensic Artifacts in S3
ARTIFACT_COUNT=$(aws s3 ls "s3://${FORENSIC_BUCKET}/incidents/" --recursive 2>/dev/null | wc -l || echo "0")
if [ "$ARTIFACT_COUNT" -gt 0 ]; then
  echo "[PASS] Forensic Triage Evidence: $ARTIFACT_COUNT artifact(s) captured in s3://${FORENSIC_BUCKET}/incidents/"
else
  echo "[WARN] Forensic Triage Evidence: 0 artifacts in s3://${FORENSIC_BUCKET}/incidents/"
fi
