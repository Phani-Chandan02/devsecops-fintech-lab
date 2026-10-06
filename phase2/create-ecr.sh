#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
REPO_NAME="payment-api"

echo "=== Creating Amazon ECR Repository: $REPO_NAME in $REGION ==="
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository \
    --repository-name "$REPO_NAME" \
    --image-scanning-configuration scanOnPush=true \
    --region "$REGION" \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab
  echo "ECR Repository $REPO_NAME created."
else
  echo "ECR Repository $REPO_NAME already exists."
fi

# Also create tagged alias phani-payment-api
if ! aws ecr describe-repositories --repository-names "phani-payment-api" --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository \
    --repository-name "phani-payment-api" \
    --image-scanning-configuration scanOnPush=true \
    --region "$REGION" \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab || true
fi
