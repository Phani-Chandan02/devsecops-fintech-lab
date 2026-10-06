#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
echo "=== VERIFYING PHASE 3: Network Security & SSM Compliance ==="

# 1. Verify Prefix List
PL_NAME="devsecops-threat-ips"
PL_ID=$(aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=$PL_NAME" --region "$REGION" --query "PrefixLists[0].PrefixListId" --output text 2>/dev/null || echo "None")
if [ "$PL_ID" != "None" ] && [ -n "$PL_ID" ]; then
  echo "[PASS] Customer Managed Prefix List: '$PL_NAME' exists ($PL_ID)"
else
  echo "[FAIL] Customer Managed Prefix List: '$PL_NAME' not found"
fi

# 2. Verify Network Firewall Rule Groups
if aws network-firewall describe-rule-group --rule-group-name fintech-domain-deny-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] Network Firewall: Stateful domain deny rule group configured"
else
  echo "[FAIL] Network Firewall: Domain deny rule group not found"
fi

if aws network-firewall describe-rule-group --rule-group-name fintech-ip-drop-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] Network Firewall: Suricata IP drop rule group configured"
else
  echo "[FAIL] Network Firewall: Suricata IP drop rule group not found"
fi

# 3. Verify Systems Manager Patch Baseline
if aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=PCI-DSS-LAB-Baseline" --region "$REGION" --query "BaselineIdentities[0].BaselineId" --output text 2>/dev/null | grep -q "pb-"; then
  echo "[PASS] SSM Patch Manager: Custom baseline 'PCI-DSS-LAB-Baseline' configured"
else
  echo "[FAIL] SSM Patch Manager: Baseline 'PCI-DSS-LAB-Baseline' not found"
fi
