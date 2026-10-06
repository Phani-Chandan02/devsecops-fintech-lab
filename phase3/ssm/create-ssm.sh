#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
ROLE_NAME="phani-ec2-ssm-role"
PROFILE_NAME="phani-ec2-profile"

echo "=== [1/4] Configuring IAM Role & Instance Profile for EC2 SSM ==="
if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  sleep 5
fi

if ! aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" 2>/dev/null; then
  aws iam create-instance-profile --instance-profile-name "$PROFILE_NAME" \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani
  aws iam add-role-to-instance-profile --instance-profile-name "$PROFILE_NAME" --role-name "$ROLE_NAME"
  sleep 5
fi

echo "=== [2/4] Creating Custom Patch Baseline: phani-PCI-DSS-LAB-Baseline ==="
BASELINE_ID=$(aws ssm describe-patch-baselines \
  --filters "Key=NAME_PREFIX,Values=phani-PCI-DSS-LAB-Baseline" \
  --query "BaselineIdentities[0].BaselineId" \
  --output text \
  --region "$REGION" 2>/dev/null || echo "None")

if [ "$BASELINE_ID" == "None" ] || [ -z "$BASELINE_ID" ]; then
  BASELINE_ID=$(aws ssm create-patch-baseline \
    --name "phani-PCI-DSS-LAB-Baseline" \
    --operating-system "AMAZON_LINUX_2023" \
    --description "Candidate: Phani - Lab baseline for PCI-DSS v4.0 patch compliance auditing" \
    --approval-rules "PatchRules=[{PatchFilterGroup={PatchFilters=[{Key=CLASSIFICATION,Values=[Security]},{Key=SEVERITY,Values=[Critical,Important]}]},ApproveAfterDays=0}]" \
    --tags Key=Owner,Value=phani Key=Candidate,Value=phani Key=Project,Value=devsecops-fintech-lab \
    --query 'BaselineId' \
    --output text \
    --region "$REGION")
  echo "    Created Patch Baseline: $BASELINE_ID"
else
  echo "    Patch Baseline exists: $BASELINE_ID"
fi

echo "=== [3/4] Registering Patch Group PCI-LAB ==="
aws ssm register-patch-baseline-for-patch-group \
  --baseline-id "$BASELINE_ID" \
  --patch-group "PCI-LAB" \
  --region "$REGION" || true

echo "=== [4/4] Launching/Verifying EC2 Runtime Node: phani-devsecops-runtime ==="
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=phani-devsecops-runtime" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --region "$REGION" 2>/dev/null || echo "None")

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region "$REGION")
  SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0].SubnetId" --output text --region "$REGION")
  
  # Create Normal App SG
  APP_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=phani-normal-app-sg" --query "SecurityGroups[0].GroupId" --output text --region "$REGION" 2>/dev/null || echo "None")
  if [ "$APP_SG" == "None" ] || [ -z "$APP_SG" ]; then
    APP_SG=$(aws ec2 create-security-group \
      --group-name "phani-normal-app-sg" \
      --description "Normal app SG for candidate Phani" \
      --vpc-id "$VPC_ID" \
      --tag-specifications 'ResourceType=security-group,Tags=[{Key=Owner,Value=phani},{Key=Candidate,Value=phani}]' \
      --query 'GroupId' \
      --output text \
      --region "$REGION")
    aws ec2 authorize-security-group-ingress --group-id "$APP_SG" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$REGION" || true
  fi

  AMI_ID=$(aws ssm get-parameter --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64" --query "Parameter.Value" --output text --region "$REGION")
  
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --iam-instance-profile Name="$PROFILE_NAME" \
    --security-group-ids "$APP_SG" \
    --subnet-id "$SUBNET_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=phani-devsecops-runtime},{Key=Owner,Value=phani},{Key=Candidate,Value=phani},{Key=PatchGroup,Value=PCI-LAB},{Key=Project,Value=devsecops-fintech-lab}]" \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region "$REGION")
  echo "    Launched EC2 node: $INSTANCE_ID"
else
  echo "    Running EC2 node: $INSTANCE_ID"
fi

echo "Systems Manager infrastructure configured successfully for Phani."
