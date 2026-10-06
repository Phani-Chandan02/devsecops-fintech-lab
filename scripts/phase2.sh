#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=========================================================="
echo " EXECUTING PHASE 2: CONTAINER SECURITY & VULNERABILITY GATES"
echo "=========================================================="

echo "[1/3] Creating Amazon ECR Repository..."
bash phase2/create-ecr.sh

echo "[2/3] Configuring Amazon Inspector Enhanced Scanning..."
bash phase2/create-inspector-config.sh

echo "[3/3] Provisioning Amazon ECS Cluster & Task Definition..."
bash phase2/create-ecs.sh

echo "=========================================================="
echo " PHASE 2 DEPLOYMENT COMPLETE"
echo "=========================================================="
