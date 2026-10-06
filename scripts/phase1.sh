#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=========================================================="
echo " EXECUTING PHASE 1: SHIFT-LEFT IaC & SECRET GOVERNANCE"
echo "=========================================================="

echo "[1/4] Storing demo secret in AWS Secrets Manager..."
if ! aws secretsmanager describe-secret --secret-id fintech/payment-api --region "$REGION" >/dev/null 2>&1; then
  aws secretsmanager create-secret \
    --name fintech/payment-api \
    --description "Payment Gateway Integration Secret" \
    --secret-string '{"service":"payment-api","api_token":"demo-initial-token"}' \
    --tags Key=Project,Value=devsecops-fintech-lab Key=Environment,Value=lab \
    --region "$REGION"
  echo "    Secret fintech/payment-api created."
else
  echo "    Secret fintech/payment-api already exists."
fi

echo "[2/4] Deploying Secrets Manager Rotation Lambda..."
ROLE_NAME="fintech-secret-rotation-role"
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  
  # Custom policy for Secrets Manager rotation
  aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name SecretsManagerRotationPermissions \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["secretsmanager:DescribeSecret","secretsmanager:GetSecretValue","secretsmanager:PutSecretValue","secretsmanager:UpdateSecretVersionStage"],"Resource":"*"}]}'
  sleep 5
fi

# Package and deploy Lambda
cd phase1/secrets
zip -q -r /tmp/secret_rotation.zip rotation_lambda.py
cd ../..

if ! aws lambda get-function --function-name fintech-secret-rotation --region "$REGION" >/dev/null 2>&1; then
  aws lambda create-function \
    --function-name fintech-secret-rotation \
    --runtime python3.12 \
    --handler rotation_lambda.handler \
    --role "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" \
    --zip-file fileb:///tmp/secret_rotation.zip \
    --timeout 30 \
    --tags Project=devsecops-fintech-lab \
    --region "$REGION"
  echo "    Lambda fintech-secret-rotation created."
else
  aws lambda update-function-code \
    --function-name fintech-secret-rotation \
    --zip-file fileb:///tmp/secret_rotation.zip \
    --region "$REGION" >/dev/null
  echo "    Lambda fintech-secret-rotation code updated."
fi

# Grant Secrets Manager permission to invoke Lambda
aws lambda add-permission \
  --function-name fintech-secret-rotation \
  --statement-id AllowSecretsManagerInvocation \
  --action lambda:InvokeFunction \
  --principal secretsmanager.amazonaws.com \
  --region "$REGION" 2>/dev/null || true

echo "[3/4] Enabling automatic 30-day secret rotation..."
aws secretsmanager rotate-secret \
  --secret-id fintech/payment-api \
  --rotation-lambda-arn "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:fintech-secret-rotation" \
  --rotation-rules '{"ScheduleExpression":"rate(30 days)"}' \
  --region "$REGION"
echo "    Rotation schedule configured to rate(30 days)."

echo "[4/4] Creating CodeBuild Phase 1 Project..."
bash phase1/create-codebuild.sh

echo "=========================================================="
echo " PHASE 1 DEPLOYMENT COMPLETE"
echo "=========================================================="
