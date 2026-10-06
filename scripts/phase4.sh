#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FORENSIC_BUCKET="fintech-devsecops-forensics-${ACCOUNT_ID}"
SOAR_ROLE="fintech-soar-role"

echo "=========================================================="
echo " EXECUTING PHASE 4: RUNTIME THREAT REMEDIATION (SOAR)"
echo "=========================================================="

echo "[1/5] Creating Encrypted S3 Forensic Bucket..."
if ! aws s3api head-bucket --bucket "$FORENSIC_BUCKET" 2>/dev/null; then
  aws s3 mb "s3://$FORENSIC_BUCKET" --region "$REGION"
  aws s3api put-bucket-encryption \
    --bucket "$FORENSIC_BUCKET" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
    --region "$REGION"
  aws s3api put-public-access-block \
    --bucket "$FORENSIC_BUCKET" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$REGION"
  echo "    Forensic bucket $FORENSIC_BUCKET created."
else
  echo "    Forensic bucket $FORENSIC_BUCKET already exists."
fi

echo "[2/5] Creating Quarantine Security Group..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region "$REGION")

QUARANTINE_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=devsecops-quarantine-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" \
  --output text \
  --region "$REGION" 2>/dev/null || echo "None")

if [ "$QUARANTINE_SG_ID" == "None" ] || [ -z "$QUARANTINE_SG_ID" ]; then
  QUARANTINE_SG_ID=$(aws ec2 create-security-group \
    --group-name "devsecops-quarantine-sg" \
    --description "Quarantine Security Group - Blocks general traffic except management" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text \
    --region "$REGION")
  
  # Allow management inbound only
  aws ec2 authorize-security-group-ingress \
    --group-id "$QUARANTINE_SG_ID" \
    --protocol tcp --port 22 --cidr 10.0.0.0/16 \
    --region "$REGION"
  
  # Remove general outbound
  DEFAULT_EGRESS=$(aws ec2 describe-security-groups --group-ids "$QUARANTINE_SG_ID" --query "SecurityGroups[0].IpPermissionsEgress" --region "$REGION")
  aws ec2 revoke-security-group-egress --group-id "$QUARANTINE_SG_ID" --ip-permissions "$DEFAULT_EGRESS" --region "$REGION" 2>/dev/null || true
  echo "    Created Quarantine SG: $QUARANTINE_SG_ID"
else
  echo "    Quarantine SG exists: $QUARANTINE_SG_ID"
fi

echo "[3/5] Verifying Amazon GuardDuty Detector..."
DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" --query "DetectorIds[0]" --output text 2>/dev/null || echo "None")
if [ "$DETECTOR_ID" == "None" ] || [ -z "$DETECTOR_ID" ]; then
  DETECTOR_ID=$(aws guardduty create-detector --enable --region "$REGION" --query "DetectorId" --output text)
  echo "    Enabled GuardDuty Detector: $DETECTOR_ID"
else
  echo "    Active GuardDuty Detector: $DETECTOR_ID"
fi

echo "[4/5] Deploying SOAR Remediation Lambda..."
if ! aws iam get-role --role-name "$SOAR_ROLE" 2>/dev/null; then
  aws iam create-role \
    --role-name "$SOAR_ROLE" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
  aws iam attach-role-policy --role-name "$SOAR_ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  aws iam attach-role-policy --role-name "$SOAR_ROLE" --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess
  aws iam attach-role-policy --role-name "$SOAR_ROLE" --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
  aws iam attach-role-policy --role-name "$SOAR_ROLE" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  sleep 5
fi

# Package and deploy Lambda
python -m zipfile -c phase4/soar/soar_lambda.zip phase4/soar/lambda_function.py

if ! aws lambda get-function --function-name phani-runtime-soar --region "$REGION" >/dev/null 2>&1; then
  aws lambda create-function \
    --function-name phani-runtime-soar \
    --runtime python3.12 \
    --handler lambda_function.handler \
    --role "arn:aws:iam::${ACCOUNT_ID}:role/${SOAR_ROLE}" \
    --zip-file fileb://phase4/soar/soar_lambda.zip \
    --timeout 300 \
    --environment "Variables={FORENSIC_BUCKET=$FORENSIC_BUCKET,QUARANTINE_SG_ID=$QUARANTINE_SG_ID}" \
    --tags Owner=phani,Candidate=phani,Project=devsecops-fintech-lab \
    --region "$REGION"
  echo "    Lambda phani-runtime-soar created."
else
  aws lambda update-function-code \
    --function-name phani-runtime-soar \
    --zip-file fileb://phase4/soar/soar_lambda.zip \
    --region "$REGION" >/dev/null
  aws lambda update-function-configuration \
    --function-name phani-runtime-soar \
    --timeout 300 \
    --environment "Variables={FORENSIC_BUCKET=$FORENSIC_BUCKET,QUARANTINE_SG_ID=$QUARANTINE_SG_ID}" \
    --region "$REGION" >/dev/null
  echo "    Lambda phani-runtime-soar updated."
fi

echo "[5/5] Creating EventBridge Rule & Attaching SOAR Target..."
aws events put-rule \
  --name "guardduty-runtime-response" \
  --event-pattern file://phase4/soar/event-pattern.json \
  --tags Key=Project,Value=devsecops-fintech-lab \
  --region "$REGION"

aws lambda add-permission \
  --function-name fintech-runtime-soar \
  --statement-id AllowEventBridgeTrigger \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn "arn:aws:events:${REGION}:${ACCOUNT_ID}:rule/guardduty-runtime-response" \
  --region "$REGION" 2>/dev/null || true

aws events put-targets \
  --rule "guardduty-runtime-response" \
  --targets "Id"="1","Arn"="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:fintech-runtime-soar" \
  --region "$REGION"

echo "=========================================================="
echo " PHASE 4 DEPLOYMENT COMPLETE"
echo "=========================================================="
