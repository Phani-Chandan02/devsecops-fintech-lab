#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PIPELINE_NAME="fintech-devsecops-pipeline"
ROLE_NAME="fintech-codepipeline-service-role"
ARTIFACT_BUCKET="fintech-codepipeline-artifacts-${ACCOUNT_ID}"

echo "=== Verifying Artifact Bucket for CodePipeline ==="
if ! aws s3api head-bucket --bucket "$ARTIFACT_BUCKET" 2>/dev/null; then
  aws s3 mb "s3://$ARTIFACT_BUCKET" --region "$REGION"
  aws s3api put-bucket-encryption \
    --bucket "$ARTIFACT_BUCKET" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
    --region "$REGION"
fi

echo "=== Creating IAM Role for CodePipeline ==="
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codepipeline.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  sleep 5
fi

PIPELINE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "Pipeline prerequisites configured. Connect via AWS CodeConnections in Console or CLI."
