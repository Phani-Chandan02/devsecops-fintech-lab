#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CLUSTER_NAME="phani-devsecops-cluster"
ROLE_NAME="phani-ecs-task-execution-role"

echo "=== Creating ECS Cluster: $CLUSTER_NAME ==="
aws ecs create-cluster \
  --cluster-name "$CLUSTER_NAME" \
  --tags key=Owner,value=phani key=Candidate,value=phani key=Project,value=devsecops-fintech-lab \
  --region "$REGION" || true

echo "=== Creating Task Execution Role ==="
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
  sleep 5
fi

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "=== Registering Task Definition: payment-api ==="
aws ecs register-task-definition \
  --family payment-api \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu "256" \
  --memory "512" \
  --execution-role-arn "$ROLE_ARN" \
  --container-definitions "[{\"name\":\"payment-api\",\"image\":\"${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/payment-api:latest\",\"portMappings\":[{\"containerPort\":80,\"hostPort\":80}]}]" \
  --tags key=Owner,value=phani key=Candidate,value=phani key=Project,value=devsecops-fintech-lab \
  --region "$REGION"

echo "ECS Cluster and Task Definition ready for Fargate deployment."
