#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
echo "=== VERIFYING PHASE 3: Network Security & SSM Compliance (Candidate: phani) ==="

# 1. Verify Prefix List
PL_NAME="phani-threat-ips"
PL_ID=$(aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=$PL_NAME" --region "$REGION" --query "PrefixLists[0].PrefixListId" --output text 2>/dev/null || echo "None")
if [ "$PL_ID" != "None" ] && [ -n "$PL_ID" ]; then
  echo "[PASS] Customer Managed Prefix List: '$PL_NAME' exists ($PL_ID)"
else
  echo "[FAIL] Customer Managed Prefix List: '$PL_NAME' not found"
fi

# 2. Verify Network Firewall Rule Groups
if aws network-firewall describe-rule-group --rule-group-name phani-domain-deny-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] Network Firewall: Stateful domain deny rule group 'phani-domain-deny-group' configured"
else
  echo "[FAIL] Network Firewall: Domain deny rule group 'phani-domain-deny-group' not found"
fi

if aws network-firewall describe-rule-group --rule-group-name phani-ip-drop-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] Network Firewall: Suricata IP drop rule group 'phani-ip-drop-group' configured"
else
  echo "[FAIL] Network Firewall: Suricata IP drop rule group 'phani-ip-drop-group' not found"
fi

# 3. Verify Firewall Policy
if aws network-firewall describe-firewall-policy --firewall-policy-name phani-firewall-policy --region "$REGION" >/dev/null 2>&1; then
  echo "[PASS] Network Firewall: Policy 'phani-firewall-policy' active"
else
  echo "[FAIL] Network Firewall: Policy 'phani-firewall-policy' not found"
fi

# 4. Verify Systems Manager Patch Baseline
if aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=phani-PCI-DSS-LAB-Baseline" --region "$REGION" --query "BaselineIdentities[0].BaselineId" --output text 2>/dev/null | grep -q "pb-"; then
  echo "[PASS] SSM Patch Manager: Custom baseline 'phani-PCI-DSS-LAB-Baseline' configured"
else
  echo "[FAIL] SSM Patch Manager: Baseline 'phani-PCI-DSS-LAB-Baseline' not found"
fi

# 5. Verify EC2 Runtime Instance
INST_STATE=$(aws ec2 describe-instances --instance-ids i-01ee2623ea4ae8598 --region "$REGION" --query "Reservations[0].Instances[0].State.Name" --output text 2>/dev/null || echo "None")
if [ "$INST_STATE" == "running" ]; then
  echo "[PASS] EC2 Instance: 'phani-devsecops-runtime' (i-01ee2623ea4ae8598) is RUNNING"
else
  echo "[WARN] EC2 Instance: Not running or not found"
fi
