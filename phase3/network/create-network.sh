#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
PL_NAME="phani-threat-ips"

echo "=== [1/4] Configuring Customer-Managed Prefix List ($PL_NAME) ==="
PL_ARN=$(aws ec2 describe-managed-prefix-lists \
  --filters "Name=prefix-list-name,Values=$PL_NAME" \
  --query "PrefixLists[0].PrefixListArn" \
  --output text \
  --region "$REGION" 2>/dev/null || echo "None")

if [ "$PL_ARN" == "None" ] || [ -z "$PL_ARN" ]; then
  PL_ARN=$(aws ec2 create-managed-prefix-list \
    --prefix-list-name "$PL_NAME" \
    --max-entries 10 \
    --address-family "IPv4" \
    --entries "Cidr=203.0.113.10/32,Description=Simulated Threat C2 IP" "Cidr=198.51.100.25/32,Description=Simulated Exfiltration Host" \
    --tag-specifications 'ResourceType=prefix-list,Tags=[{Key=Owner,Value=phani},{Key=Candidate,Value=phani},{Key=Project,Value=devsecops-fintech-lab}]' \
    --query 'PrefixList.PrefixListArn' \
    --output text \
    --region "$REGION")
  echo "    Created Prefix List: $PL_ARN"
else
  echo "    Prefix List exists: $PL_ARN"
fi

echo "=== [2/4] Creating Stateful Domain Deny Rule Group: phani-domain-deny-group ==="
if ! aws network-firewall describe-rule-group --rule-group-name phani-domain-deny-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  aws network-firewall create-rule-group \
    --rule-group-name phani-domain-deny-group \
    --type STATEFUL \
    --capacity 100 \
    --rule-group file://phase3/network/firewall-domain-rules.json \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab \
    --region "$REGION"
  echo "    Created Domain Deny Rule Group"
else
  echo "    Domain Deny Rule Group already exists"
fi

echo "=== [3/4] Creating Suricata IP Drop Rule Group: phani-ip-drop-group ==="
sed "s|REPLACE_WITH_PREFIX_LIST_ARN|$PL_ARN|g" phase3/network/firewall-ip-rules.json > resolved-ip-rules.json

if ! aws network-firewall describe-rule-group --rule-group-name phani-ip-drop-group --type STATEFUL --region "$REGION" >/dev/null 2>&1; then
  aws network-firewall create-rule-group \
    --rule-group-name phani-ip-drop-group \
    --type STATEFUL \
    --capacity 100 \
    --rule-group file://resolved-ip-rules.json \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab \
    --region "$REGION"
  echo "    Created Suricata IP Drop Rule Group"
else
  echo "    Suricata IP Drop Rule Group already exists"
fi

echo "=== [4/4] Creating Firewall Policy: phani-firewall-policy ==="
DOMAIN_ARN=$(aws network-firewall describe-rule-group --rule-group-name phani-domain-deny-group --type STATEFUL --query 'RuleGroupResponse.RuleGroupArn' --output text --region "$REGION")
IP_ARN=$(aws network-firewall describe-rule-group --rule-group-name phani-ip-drop-group --type STATEFUL --query 'RuleGroupResponse.RuleGroupArn' --output text --region "$REGION")

if ! aws network-firewall describe-firewall-policy --firewall-policy-name phani-firewall-policy --region "$REGION" >/dev/null 2>&1; then
  aws network-firewall create-firewall-policy \
    --firewall-policy-name phani-firewall-policy \
    --firewall-policy "StatelessDefaultActions=[\"aws:forward_to_sfe\"],StatelessFragmentDefaultActions=[\"aws:forward_to_sfe\"],StatefulRuleGroupReferences=[{ResourceArn=\"$DOMAIN_ARN\"},{ResourceArn=\"$IP_ARN\"}]" \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab \
    --region "$REGION"
  echo "    Created Firewall Policy"
else
  echo "    Firewall Policy already exists"
fi

echo "Network perimeter rules & policy successfully configured."
