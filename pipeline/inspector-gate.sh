#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:?AWS_DEFAULT_REGION is required}"
REPO="${ECR_REPOSITORY:?ECR_REPOSITORY is required}"
TAG="${IMAGE_TAG:-latest}"

 echo "Waiting for Amazon ECR enhanced scan to complete..."
aws ecr wait image-scan-complete --repository-name "$REPO" --image-id imageTag="$TAG" --region "$REGION"

COUNTS=$(aws ecr describe-image-scan-findings \
  --repository-name "$REPO" \
  --image-id imageTag="$TAG" \
  --region "$REGION" \
  --query 'imageScanFindings.findingSeverityCounts' \
  --output json)

echo "Inspector/ECR severity counts: $COUNTS"

CRITICAL=$(python3 -c 'import json,sys; d=(json.load(sys.stdin) or {}); print(int(d.get("CRITICAL",0)))' <<< "$COUNTS")
HIGH=$(python3 -c 'import json,sys; d=(json.load(sys.stdin) or {}); print(int(d.get("HIGH",0)))' <<< "$COUNTS")

echo "CRITICAL=$CRITICAL HIGH=$HIGH"

if (( CRITICAL > 0 || HIGH > 0 )); then
  echo "BLOCK DEPLOY: HIGH/CRITICAL CVEs detected by Amazon Inspector"
  exit 1
fi

echo "DEPLOYMENT ALLOWED: no HIGH/CRITICAL findings"
