#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
REPO_NAME="payment-api"

echo "=== Creating Amazon ECR Repository: $REPO_NAME in $REGION ==="
if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "ECR Repository $REPO_NAME already exists."
else
  aws ecr create-repository \
    --repository-name "$REPO_NAME" \
    --image-scanning-configuration scanOnPush=true \
    --region "$REGION" \
    --tags Key=Project,Value=devsecops-fintech-lab Key=Environment,Value=lab
  echo "ECR Repository created successfully."
fi
