#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME="phani-devsecops-phase1"
ROLE_NAME="phani-codebuild-service-role"

echo "=== [1/2] Creating/Verifying IAM Role for CodeBuild ($ROLE_NAME) ==="
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codebuild.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani
  
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  sleep 5
fi

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "=== [2/2] Creating/Updating CodeBuild Project: $PROJECT_NAME ==="
if aws codebuild batch-get-projects --names "$PROJECT_NAME" --region "$REGION" --query "projects[0].name" --output text 2>/dev/null | grep -q "$PROJECT_NAME"; then
  echo "Project $PROJECT_NAME already exists."
else
  aws codebuild create-project \
    --name "$PROJECT_NAME" \
    --description "Candidate: Phani - Phase 1 Shift-Left Checkov IaC & detect-secrets governance scan" \
    --source '{"type":"CODEPIPELINE","buildspec":"phase1/buildspec.yml"}' \
    --artifacts '{"type":"CODEPIPELINE"}' \
    --environment '{"type":"LINUX_CONTAINER","image":"aws/codebuild/amazonlinux2-x86_64-standard:5.0","computeType":"BUILD_GENERAL1_SMALL","privilegedMode":true}' \
    --service-role "$ROLE_ARN" \
    --tags '[{"key":"Owner","value":"phani"},{"key":"Candidate","value":"phani"},{"key":"Project","value":"devsecops-fintech-lab"},{"key":"Environment","value":"lab"}]' \
    --region "$REGION"
  echo "Project $PROJECT_NAME created successfully."
fi
