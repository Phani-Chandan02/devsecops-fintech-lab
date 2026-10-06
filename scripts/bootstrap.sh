#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " AWS DEVSECOPS FINTECH LAB BOOTSTRAP (STEP 0)"
echo "=========================================================="

export AWS_DEFAULT_REGION="ap-south-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

echo "[*] AWS Account ID: $ACCOUNT_ID"
echo "[*] IAM Identity:   $USER_ARN"
echo "[*] Region:         $AWS_DEFAULT_REGION"

if [ -z "$ACCOUNT_ID" ]; then
  echo "[!] Error: Invalid AWS Credentials. Check configuration."
  exit 1
fi

echo "[+] Step 0 Verified. Cloud environment ready for deployment."
