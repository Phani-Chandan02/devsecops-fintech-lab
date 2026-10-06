#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"

echo "=========================================================="
echo " EXECUTING PHASE 3: NETWORK BOUNDARIES & SSM COMPLIANCE"
echo "=========================================================="

echo "[1/2] Deploying Network Firewall Rules & Dynamic Prefix List..."
bash phase3/network/create-network.sh

echo "[2/2] Configuring Systems Manager Patch Baseline & Roles..."
bash phase3/ssm/create-ssm.sh

echo "=========================================================="
echo " PHASE 3 DEPLOYMENT COMPLETE"
echo "=========================================================="
