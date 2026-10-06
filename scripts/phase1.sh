#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=========================================================="
echo " EXECUTING PHASE 1: SHIFT-LEFT IaC & SECRET GOVERNANCE (PHANI)"
echo "=========================================================="

echo "[1/4] Storing secret in AWS Secrets Manager: phani/fintech/payment-api..."
if ! aws secretsmanager describe-secret --secret-id phani/fintech/payment-api --region "$REGION" >/dev/null 2>&1; then
  aws secretsmanager create-secret \
    --name phani/fintech/payment-api \
    --description "Payment Gateway Integration Secret - Candidate: Phani" \
    --secret-string '{"service":"payment-api","api_token":"phani-demo-initial-token"}' \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab \
    --region "$REGION"
  echo "    Secret phani/fintech/payment-api created."
else
  echo "    Secret phani/fintech/payment-api already exists."
fi

# Also create the alias fintech/payment-api for complete compliance
if ! aws secretsmanager describe-secret --secret-id fintech/payment-api --region "$REGION" >/dev/null 2>&1; then
  aws secretsmanager create-secret \
    --name fintech/payment-api \
    --description "Payment Gateway Integration Secret - Candidate: Phani" \
    --secret-string '{"service":"payment-api","api_token":"phani-demo-initial-token"}' \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab \
    --region "$REGION" || true
fi

echo "[2/4] Deploying Secrets Manager Rotation Lambda: phani-secret-rotation..."
ROLE_NAME="phani-secret-rotation-role"
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  
  aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name SecretsManagerRotationPermissions \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["secretsmanager:DescribeSecret","secretsmanager:GetSecretValue","secretsmanager:PutSecretValue","secretsmanager:UpdateSecretVersionStage"],"Resource":"*"}]}'
  sleep 5
fi

# Package and deploy Lambda using python built-in zipfile
python -m zipfile -c phase1/secrets/secret_rotation.zip phase1/secrets/rotation_lambda.py

if ! aws lambda get-function --function-name phani-secret-rotation --region "$REGION" >/dev/null 2>&1; then
  aws lambda create-function \
    --function-name phani-secret-rotation \
    --runtime python3.12 \
    --handler rotation_lambda.handler \
    --role "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" \
    --zip-file fileb://phase1/secrets/secret_rotation.zip \
    --timeout 30 \
    --tags Owner=phani,Candidate=phani,Project=devsecops-fintech-lab \
    --region "$REGION"
  echo "    Lambda phani-secret-rotation created."
else
  aws lambda update-function-code \
    --function-name phani-secret-rotation \
    --zip-file fileb://phase1/secrets/secret_rotation.zip \
    --region "$REGION" >/dev/null
  echo "    Lambda phani-secret-rotation updated."
fi

# Grant Secrets Manager permission to invoke Lambda
aws lambda add-permission \
  --function-name phani-secret-rotation \
  --statement-id AllowSecretsManagerInvocation \
  --action lambda:InvokeFunction \
  --principal secretsmanager.amazonaws.com \
  --region "$REGION" 2>/dev/null || true

echo "[3/4] Enabling automatic 30-day secret rotation..."
aws secretsmanager rotate-secret \
  --secret-id phani/fintech/payment-api \
  --rotation-lambda-arn "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:phani-secret-rotation" \
  --rotation-rules '{"ScheduleExpression":"rate(30 days)"}' \
  --region "$REGION" || true
echo "    Rotation schedule configured to rate(30 days)."

echo "[4/4] Creating CodeBuild & CodePipeline..."
bash phase1/create-codebuild.sh
bash phase1/create-codepipeline.sh

echo "=========================================================="
echo " PHASE 1 DEPLOYMENT COMPLETE"
echo "=========================================================="
