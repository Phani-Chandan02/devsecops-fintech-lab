#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
echo "=== VERIFYING PHASE 1: Shift-Left IaC & Secret Governance (Candidate: phani) ==="

# 1. Verify Secret
SECRET_NAME="phani/fintech/payment-api"
if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] Secrets Manager: Secret '$SECRET_NAME' exists"
else
  echo "[FAIL] Secrets Manager: Secret '$SECRET_NAME' not found"
  exit 1
fi

# 2. Verify Rotation Schedule
SCHEDULE=$(aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" --query "RotationRules.ScheduleExpression" --output text 2>/dev/null || echo "None")
if [ "$SCHEDULE" == "rate(30 days)" ]; then
  echo "[PASS] Secrets Manager Rotation: Automatic rotation set to '$SCHEDULE'"
else
  echo "[FAIL] Secrets Manager Rotation: Schedule is '$SCHEDULE', expected 'rate(30 days)'"
fi

# 3. Verify Rotation Lambda
if aws lambda get-function --function-name phani-secret-rotation --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] Lambda: Function 'phani-secret-rotation' active"
else
  echo "[FAIL] Lambda: Function 'phani-secret-rotation' not found"
fi

# 4. Verify CodeBuild Project
if aws codebuild batch-get-projects --names phani-devsecops-phase1 --region "$REGION" --query "projects[0].name" --output text 2>/dev/null | grep -q "phani-devsecops-phase1"; then
  echo "[PASS] CodeBuild: Project 'phani-devsecops-phase1' configured"
else
  echo "[FAIL] CodeBuild: Project 'phani-devsecops-phase1' not found"
fi

# 5. Verify CodePipeline
if aws codepipeline get-pipeline --name phani-devsecops-pipeline --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] CodePipeline: Pipeline 'phani-devsecops-pipeline' active"
else
  echo "[FAIL] CodePipeline: Pipeline 'phani-devsecops-pipeline' not found"
fi
