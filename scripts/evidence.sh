#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
EVIDENCE_DIR="evidence"
mkdir -p "$EVIDENCE_DIR/phase1" "$EVIDENCE_DIR/phase2" "$EVIDENCE_DIR/phase3" "$EVIDENCE_DIR/phase4"

echo "[*] Collecting Phase 1 CLI Evidence..."
aws secretsmanager describe-secret --secret-id fintech/payment-api --region "$REGION" > "$EVIDENCE_DIR/phase1/secret-config.json" 2>&1 || true
aws lambda get-function --function-name fintech-secret-rotation --region "$REGION" > "$EVIDENCE_DIR/phase1/rotation-lambda.json" 2>&1 || true

echo "[*] Collecting Phase 2 CLI Evidence..."
aws ecr describe-repositories --repository-names payment-api --region "$REGION" > "$EVIDENCE_DIR/phase2/ecr-repo.json" 2>&1 || true
aws ecr get-registry-scanning-configuration --region "$REGION" > "$EVIDENCE_DIR/phase2/inspector-config.json" 2>&1 || true

echo "[*] Collecting Phase 3 CLI Evidence..."
aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=devsecops-threat-ips" --region "$REGION" > "$EVIDENCE_DIR/phase3/prefix-list.json" 2>&1 || true
aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=PCI-DSS-LAB-Baseline" --region "$REGION" > "$EVIDENCE_DIR/phase3/patch-baseline.json" 2>&1 || true

echo "[*] Collecting Phase 4 CLI Evidence..."
aws s3api get-bucket-encryption --bucket "fintech-devsecops-forensics-${ACCOUNT_ID}" > "$EVIDENCE_DIR/phase4/s3-encryption.json" 2>&1 || true
aws events describe-rule --name guardduty-runtime-response --region "$REGION" > "$EVIDENCE_DIR/phase4/eventbridge-rule.json" 2>&1 || true
aws lambda get-function --function-name fintech-runtime-soar --region "$REGION" > "$EVIDENCE_DIR/phase4/soar-lambda.json" 2>&1 || true

echo "[+] Evidence collection complete. Saved under $EVIDENCE_DIR/"
