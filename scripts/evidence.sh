#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
EVIDENCE_DIR="evidence"
mkdir -p "$EVIDENCE_DIR/phase1" "$EVIDENCE_DIR/phase2" "$EVIDENCE_DIR/phase3" "$EVIDENCE_DIR/phase4"

echo "[*] Collecting Phase 1 CLI Evidence (Candidate: phani)..."
aws secretsmanager describe-secret --secret-id phani/fintech/payment-api --region "$REGION" > "$EVIDENCE_DIR/phase1/secret-config.json" 2>&1 || true
aws lambda get-function --function-name phani-secret-rotation --region "$REGION" > "$EVIDENCE_DIR/phase1/rotation-lambda.json" 2>&1 || true
aws codebuild batch-get-projects --names phani-devsecops-phase1 --region "$REGION" > "$EVIDENCE_DIR/phase1/codebuild-project.json" 2>&1 || true
aws codepipeline get-pipeline --name phani-devsecops-pipeline --region "$REGION" > "$EVIDENCE_DIR/phase1/codepipeline-definition.json" 2>&1 || true
aws codepipeline get-pipeline-state --name phani-devsecops-pipeline --region "$REGION" > "$EVIDENCE_DIR/phase1/codepipeline-state.json" 2>&1 || true

echo "[*] Collecting Phase 2 CLI Evidence (Candidate: phani)..."
aws ecr describe-repositories --repository-names payment-api --region "$REGION" > "$EVIDENCE_DIR/phase2/ecr-repo.json" 2>&1 || true
aws ecr get-registry-scanning-configuration --region "$REGION" > "$EVIDENCE_DIR/phase2/inspector-config.json" 2>&1 || true
aws codebuild batch-get-projects --names phani-devsecops-phase2 --region "$REGION" > "$EVIDENCE_DIR/phase2/codebuild-project.json" 2>&1 || true
aws ecs describe-clusters --clusters phani-devsecops-cluster --region "$REGION" > "$EVIDENCE_DIR/phase2/ecs-cluster.json" 2>&1 || true
aws ecs describe-services --cluster phani-devsecops-cluster --services payment-api-service --region "$REGION" > "$EVIDENCE_DIR/phase2/ecs-service.json" 2>&1 || true
aws ecs list-tasks --cluster phani-devsecops-cluster --region "$REGION" > "$EVIDENCE_DIR/phase2/ecs-tasks.json" 2>&1 || true

echo "[*] Collecting Phase 3 CLI Evidence (Candidate: phani)..."
aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=phani-threat-ips" --region "$REGION" > "$EVIDENCE_DIR/phase3/prefix-list.json" 2>&1 || true
aws network-firewall describe-rule-group --rule-group-name phani-domain-deny-group --type STATEFUL --region "$REGION" > "$EVIDENCE_DIR/phase3/domain-deny-group.json" 2>&1 || true
aws network-firewall describe-rule-group --rule-group-name phani-ip-drop-group --type STATEFUL --region "$REGION" > "$EVIDENCE_DIR/phase3/ip-drop-group.json" 2>&1 || true
aws network-firewall describe-firewall-policy --firewall-policy-name phani-firewall-policy --region "$REGION" > "$EVIDENCE_DIR/phase3/firewall-policy.json" 2>&1 || true
aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=phani-PCI-DSS-LAB-Baseline" --region "$REGION" > "$EVIDENCE_DIR/phase3/patch-baseline.json" 2>&1 || true
aws ssm describe-instance-information --region "$REGION" > "$EVIDENCE_DIR/phase3/ssm-instances.json" 2>&1 || true

echo "[*] Collecting Phase 4 CLI Evidence (Candidate: phani)..."
aws s3api get-bucket-encryption --bucket "phani-fintech-forensics-${ACCOUNT_ID}" > "$EVIDENCE_DIR/phase4/s3-encryption.json" 2>&1 || true
aws s3api get-public-access-block --bucket "phani-fintech-forensics-${ACCOUNT_ID}" > "$EVIDENCE_DIR/phase4/s3-public-access-block.json" 2>&1 || true
aws ec2 describe-security-groups --filters "Name=group-name,Values=phani-quarantine-sg" --region "$REGION" > "$EVIDENCE_DIR/phase4/quarantine-sg.json" 2>&1 || true
aws events describe-rule --name guardduty-runtime-response --region "$REGION" > "$EVIDENCE_DIR/phase4/eventbridge-rule.json" 2>&1 || true
aws lambda get-function --function-name phani-runtime-soar --region "$REGION" > "$EVIDENCE_DIR/phase4/soar-lambda.json" 2>&1 || true
aws s3 ls "s3://phani-fintech-forensics-${ACCOUNT_ID}/incidents/" --recursive > "$EVIDENCE_DIR/phase4/forensic-s3-objects.txt" 2>&1 || true

echo "[+] Evidence collection complete. Saved under $EVIDENCE_DIR/"
