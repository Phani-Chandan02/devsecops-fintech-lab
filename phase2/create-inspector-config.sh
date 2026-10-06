#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
REPO_NAME="payment-api"

echo "=== Enabling Amazon Inspector Enhanced Scanning for ECR ==="
aws inspector2 enable --resource-types ECR --region "$REGION" || true

echo "=== Setting ECR Registry Scanning Configuration to ENHANCED ==="
aws ecr put-registry-scanning-configuration \
  --scan-type ENHANCED \
  --rules "[{\"repositoryFilters\":[{\"filter\":\"$REPO_NAME\",\"filterType\":\"WILDCARD\"}],\"scanFrequency\":\"SCAN_ON_PUSH\"}]" \
  --region "$REGION"

echo "Inspector Enhanced Scanning successfully configured for $REPO_NAME."
