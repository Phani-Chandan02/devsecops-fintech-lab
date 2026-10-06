#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
echo "=== VERIFYING PHASE 2: Container Security & Vulnerability Gates (Candidate: phani) ==="

# 1. Verify ECR Repository
REPO_NAME="payment-api"
if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] ECR Repository: '$REPO_NAME' active in $REGION"
else
  echo "[FAIL] ECR Repository: '$REPO_NAME' not found"
fi

# 2. Verify Inspector / ECR Scanning Configuration
SCAN_TYPE=$(aws ecr get-registry-scanning-configuration --region "$REGION" --query "scanningConfiguration.scanType" --output text 2>/dev/null || echo "BASIC")
if [ "$SCAN_TYPE" == "ENHANCED" ]; then
  echo "[PASS] ECR Scanning: Enhanced scanning powered by Amazon Inspector is active"
else
  echo "[WARN] ECR Scanning: Scan type is '$SCAN_TYPE'. Ensure Inspector ECR scanning is enabled."
fi

# 3. Verify CodeBuild Phase 2 Project
if aws codebuild batch-get-projects --names phani-devsecops-phase2 --region "$REGION" --query "projects[0].name" --output text 2>/dev/null | grep -q "phani-devsecops-phase2"; then
  echo "[PASS] CodeBuild: Project 'phani-devsecops-phase2' configured"
else
  echo "[FAIL] CodeBuild: Project 'phani-devsecops-phase2' not found"
fi

# 4. Verify ECS Cluster
CLUSTER_NAME="phani-devsecops-cluster"
if aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" --query "clusters[0].status" --output text 2>/dev/null | grep -q "ACTIVE"; then
  echo "[PASS] ECS Cluster: '$CLUSTER_NAME' is ACTIVE"
else
  echo "[FAIL] ECS Cluster: '$CLUSTER_NAME' not found or inactive"
fi

# 5. Verify Task Definition
if aws ecs describe-task-definition --task-definition payment-api --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] ECS Task Definition: 'payment-api' registered"
else
  echo "[FAIL] ECS Task Definition: 'payment-api' not found"
fi

# 6. Verify Running Fargate Task
TASK_COUNT=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --region "$REGION" --query "length(taskArns)" --output text 2>/dev/null || echo "0")
if [ "$TASK_COUNT" -gt 0 ]; then
  echo "[PASS] ECS Fargate Tasks: $TASK_COUNT task(s) running in '$CLUSTER_NAME'"
else
  echo "[WARN] ECS Fargate Tasks: 0 running tasks found in '$CLUSTER_NAME'"
fi
