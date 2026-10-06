#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PIPELINE_NAME="phani-devsecops-pipeline"
ROLE_NAME="phani-codepipeline-service-role"
ARTIFACT_BUCKET="phani-codepipeline-artifacts-${ACCOUNT_ID}"
CONNECTION_ARN="arn:aws:codeconnections:ap-south-1:435023701114:connection/1958f30d-2ec2-4ae0-b5c9-59add21bdb4f"

echo "=== [1/3] Creating Pipeline Artifact Bucket: $ARTIFACT_BUCKET ==="
if ! aws s3api head-bucket --bucket "$ARTIFACT_BUCKET" 2>/dev/null; then
  aws s3 mb "s3://$ARTIFACT_BUCKET" --region "$REGION"
  aws s3api put-bucket-encryption \
    --bucket "$ARTIFACT_BUCKET" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
    --region "$REGION"
  aws s3api put-public-access-block \
    --bucket "$ARTIFACT_BUCKET" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$REGION"
fi

echo "=== [2/3] Creating IAM Service Role for CodePipeline ==="
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codepipeline.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani
  
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  
  # Allow CodeStar connection pass-through
  aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name CodeConnectionAccess \
    --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"codeconnections:UseConnection\",\"codestar-connections:UseConnection\"],\"Resource\":\"*\"}]}"
  sleep 5
fi

PIPELINE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "=== [3/3] Creating AWS CodePipeline: $PIPELINE_NAME ==="
cat > pipeline-definition.json <<JSON
{
  "pipeline": {
    "name": "$PIPELINE_NAME",
    "roleArn": "$PIPELINE_ROLE_ARN",
    "artifactStore": {
      "type": "S3",
      "location": "$ARTIFACT_BUCKET"
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "GitHub_Source",
            "actionTypeId": {
              "category": "Source",
              "owner": "AWS",
              "provider": "CodeStarSourceConnection",
              "version": "1"
            },
            "outputArtifacts": [
              {
                "name": "SourceArtifact"
              }
            ],
            "configuration": {
              "ConnectionArn": "$CONNECTION_ARN",
              "FullRepositoryId": "Phani-Chandan02/devsecops-fintech-lab",
              "BranchName": "main"
            },
            "runOrder": 1
          }
        ]
      },
      {
        "name": "IaC_and_Secret_Security_Scan",
        "actions": [
          {
            "name": "Checkov_and_DetectSecrets_Gate",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "inputArtifacts": [
              {
                "name": "SourceArtifact"
              }
            ],
            "outputArtifacts": [
              {
                "name": "SecurityBuildArtifact"
              }
            ],
            "configuration": {
              "ProjectName": "phani-devsecops-phase1"
            },
            "runOrder": 1
          }
        ]
      }
    ]
  },
  "tags": [
    {
      "key": "Owner",
      "value": "phani"
    },
    {
      "key": "Candidate",
      "value": "phani"
    },
    {
      "key": "Project",
      "value": "devsecops-fintech-lab"
    }
  ]
}
JSON

if aws codepipeline get-pipeline --name "$PIPELINE_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "Pipeline $PIPELINE_NAME exists, updating definition..."
  aws codepipeline update-pipeline --cli-input-json file://pipeline-definition.json --region "$REGION"
else
  aws codepipeline create-pipeline --cli-input-json file://pipeline-definition.json --region "$REGION"
  echo "Pipeline $PIPELINE_NAME created successfully."
fi
