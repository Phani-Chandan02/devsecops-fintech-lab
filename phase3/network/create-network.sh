#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
VPC_NAME="devsecops-lab-vpc"

echo "=== [1/5] Configuring Customer-Managed Prefix List ==="
PREFIX_LIST_ARN=$(aws ec2 describe-managed-prefix-lists \
  --filters "Name=prefix-list-name,Values=devsecops-threat-ips" \
  --query "PrefixLists[0].PrefixListArn" \
  --output text \
  --region "$REGION" 2>/dev/null || echo "None")

if [ "$PREFIX_LIST_ARN" == "None" ] || [ -z "$PREFIX_LIST_ARN" ]; then
  PREFIX_LIST_ARN=$(aws ec2 create-managed-prefix-list \
    --cli-input-json file://phase3/network/prefix-list.json \
    --query 'PrefixList.PrefixListArn' \
    --output text \
    --region "$REGION")
  echo "Created Prefix List: $PREFIX_LIST_ARN"
else
  echo "Prefix List exists: $PREFIX_LIST_ARN"
fi

echo "=== [2/5] Creating Stateful Domain Deny Rule Group ==="
if ! aws network-firewall describe-rule-group --rule-group-name fintech-domain-deny-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  aws network-firewall create-rule-group \
    --rule-group-name fintech-domain-deny-group \
    --type STATEFUL \
    --capacity 100 \
    --rule-group file://phase3/network/firewall-domain-rules.json \
    --region "$REGION"
  echo "Created Domain Deny Rule Group"
else
  echo "Domain Deny Rule Group already exists"
fi

echo "=== [3/5] Creating Suricata IP Drop Rule Group ==="
sed "s|REPLACE_WITH_PREFIX_LIST_ARN|$PREFIX_LIST_ARN|g" phase3/network/firewall-ip-rules.json > /tmp/resolved-ip-rules.json

if ! aws network-firewall describe-rule-group --rule-group-name fintech-ip-drop-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  aws network-firewall create-rule-group \
    --rule-group-name fintech-ip-drop-group \
    --type STATEFUL \
    --capacity 100 \
    --rule-group file:///tmp/resolved-ip-rules.json \
    --region "$REGION"
  echo "Created Suricata IP Drop Rule Group"
else
  echo "Suricata IP Drop Rule Group already exists"
fi

echo "=== [4/5] Creating Firewall Policy ==="
DOMAIN_ARN=$(aws network-firewall describe-rule-group --rule-group-name fintech-domain-deny-group --type STATEFUL --query 'RuleGroupResponse.RuleGroupArn' --output text --region "$REGION")
IP_ARN=$(aws network-firewall describe-rule-group --rule-group-name fintech-ip-drop-group --type STATEFUL --query 'RuleGroupResponse.RuleGroupArn' --output text --region "$REGION")

if ! aws network-firewall describe-firewall-policy --firewall-policy-name fintech-firewall-policy --region "$REGION" >/dev/null 2>&1; then
  aws network-firewall create-firewall-policy \
    --firewall-policy-name fintech-firewall-policy \
    --firewall-policy "StatelessDefaultActions=[\"aws:forward_to_sfe\"],StatelessFragmentDefaultActions=[\"aws:forward_to_sfe\"],StatefulRuleGroupReferences=[{ResourceArn=\"$DOMAIN_ARN\"},{ResourceArn=\"$IP_ARN\"}]" \
    --region "$REGION"
  echo "Created Firewall Policy"
else
  echo "Firewall Policy already exists"
fi

echo "Network security perimeter components ready."
