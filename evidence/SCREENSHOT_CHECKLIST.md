# Candidate Phani - Comprehensive Evidence & Screenshot Guide

**Candidate Name**: `phani`  
**AWS Account ID**: `435023701114`  
**Region**: `ap-south-1` (Asia Pacific - Mumbai)  
**IAM Role / User**: `arn:aws:iam::435023701114:user/phani-cli`  
**GitHub Repository**: [devsecops-fintech-lab](https://github.com/Phani-Chandan02/devsecops-fintech-lab)  

> [!IMPORTANT]
> All resources deployed in this examination contain the candidate prefix/tag `phani` for explicit invigilator verification. Below is the master matrix of screenshots with direct AWS Management Console URLs and verified CLI outputs.

---

## Master Screenshot Checklist

### PHASE 1: Shift-Left IaC Security & Secret Governance

| ID | Console Location / Feature | Direct AWS Console URL | What Must Be Visible in Screenshot | Verified CLI Proof |
| :--- | :--- | :--- | :--- | :--- |
| **P1-01** | GitHub Repository | `https://github.com/Phani-Chandan02/devsecops-fintech-lab` | Branch `main`, directories `app/`, `terraform/`, `phase1/`, `phase2/`, `phase4/`, `scripts/` | `git remote -v` |
| **P1-02** | AWS CodeConnections | [CodeConnections Settings](https://ap-south-1.console.aws.amazon.com/codesuite/settings/connections?region=ap-south-1) | Connection `devsecops-fintech-connection`, Provider: GitHub, Status: **`Available`** | `aws codeconnections list-connections --region ap-south-1` |
| **P1-03** | AWS CodePipeline Overview | [CodePipeline Console](https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/phani-devsecops-pipeline/view?region=ap-south-1) | Pipeline `phani-devsecops-pipeline` showing 3 stages: Source, IaC_and_Secret_Security_Scan, Container_Security_and_Inspector_Gate | `aws codepipeline get-pipeline --name phani-devsecops-pipeline` |
| **P1-04** | AWS CodeBuild Project | [CodeBuild Console](https://ap-south-1.console.aws.amazon.com/codesuite/codebuild/projects/phani-devsecops-phase1/view?region=ap-south-1) | Project name `phani-devsecops-phase1`, tags `Owner=phani`, `Candidate=phani` | `aws codebuild batch-get-projects --names phani-devsecops-phase1` |
| **P1-05** | Vulnerable IaC Code | IDE / GitHub | `terraform/vulnerable/main.tf` with public S3 bucket (`acl = "public-read"`) and open security group (`0.0.0.0/0`) | `cat terraform/vulnerable/main.tf` |
| **P1-06** | Checkov Scan Failure | CodeBuild Execution Log | Output showing Checkov static analysis failure: `CKV_AWS_20`, `CKV_AWS_260` failed | `checkov -d terraform/vulnerable` |
| **P1-07** | `detect-secrets` Failure | CodeBuild Execution Log | Output showing detect-secrets finding hardcoded credentials: `dummy_stripe_secret_key` | `detect-secrets scan terraform/vulnerable/` |
| **P1-08** | CodePipeline Blocked (IaC) | CodePipeline History | Stage 2 `IaC_and_Secret_Security_Scan` status **`Failed`** (Red) blocking release | `aws codepipeline get-pipeline-state --name phani-devsecops-pipeline` |
| **P1-09** | Remediated IaC Code | IDE / GitHub | `terraform/secure/main.tf` with AES256 server-side encryption, public access block, private CIDR ingress | `cat terraform/secure/main.tf` |
| **P1-10** | CodePipeline Green (IaC) | CodePipeline History | Stage 2 `IaC_and_Secret_Security_Scan` status **`Succeeded`** (Green) after fix | `aws codepipeline get-pipeline-state --name phani-devsecops-pipeline` |
| **P1-11** | AWS Secrets Manager | [Secrets Manager Console](https://ap-south-1.console.aws.amazon.com/secretsmanager/listsecrets?region=ap-south-1) | Secret name `phani/fintech/payment-api`, JSON key/value structure | `aws secretsmanager describe-secret --secret-id phani/fintech/payment-api` |
| **P1-12** | Rotation Lambda Function | [Lambda Console](https://ap-south-1.console.aws.amazon.com/lambda/home?region=ap-south-1#/functions/phani-secret-rotation) | Function `phani-secret-rotation`, 4-step lifecycle (`createSecret`, `setSecret`, `testSecret`, `finishSecret`) | `aws lambda get-function --function-name phani-secret-rotation` |
| **P1-13** | Secrets Rotation Schedule | Secrets Manager Detail | Rotation status: **`Enabled`**, Schedule: **`rate(30 days)`** (PCI-DSS Req 8.6) | `aws secretsmanager describe-secret --secret-id phani/fintech/payment-api --query "RotationRules"` |

---

### PHASE 2: Container Security & Vulnerability Guardrails

| ID | Console Location / Feature | Direct AWS Console URL | What Must Be Visible in Screenshot | Verified CLI Proof |
| :--- | :--- | :--- | :--- | :--- |
| **P2-01** | Amazon ECR Repository | [ECR Console](https://ap-south-1.console.aws.amazon.com/ecr/repositories/private/435023701114/payment-api?region=ap-south-1) | Repository `payment-api` and `phani-payment-api` in `ap-south-1` | `aws ecr describe-repositories --repository-names payment-api` |
| **P2-02** | ECR Images Pushed | ECR Repository Details | Tags `latest`, image digests, push timestamps | `aws ecr list-images --repository-name payment-api` |
| **P2-03** | Amazon Inspector Enhanced | [ECR Registry Settings](https://ap-south-1.console.aws.amazon.com/ecr/registry-settings?region=ap-south-1) | Scan type: **`Enhanced scanning`**, Continuous scanning enabled | `aws ecr get-registry-scanning-configuration` |
| **P2-04** | Amazon Inspector Findings | [Inspector Console](https://ap-south-1.console.aws.amazon.com/inspector/v2/home?region=ap-south-1#/findings) | Inspector dashboard showing findings categorized by severity | `aws inspector2 list-findings --max-results 5` |
| **P2-05** | ECR Vulnerability Findings | ECR Image Vulnerabilities | Image scan results showing **CRITICAL: 1** (`Platform End Of Life`) on `nginx:1.14.2` | `aws ecr describe-image-scan-findings --repository-name payment-api --image-id imageTag=latest` |
| **P2-06** | Inspector Gate Block Log | CodeBuild Execution Log | Output: `[!] BLOCK DEPLOYMENT: Policy Violation Detected! Found 1 CRITICAL and 0 HIGH vulnerabilities.` Exited with code 1 | `python phase2/inspector_gate.py` |
| **P2-07** | CodePipeline Blocked (Container) | CodePipeline History | Stage 3 `Container_Security_and_Inspector_Gate` status **`Failed`** (Red) preventing vulnerable image rollout | `aws codepipeline get-pipeline-state --name phani-devsecops-pipeline` |
| **P2-08** | Remediated Dockerfile | IDE / GitHub | `app/Dockerfile` using hardened minimal base image `python:3.11-alpine` | `cat app/Dockerfile` |
| **P2-09** | Inspector Gate Pass Log | CodeBuild Execution Log | Output: `[+] DEPLOYMENT ALLOWED: 0 CRITICAL and 0 HIGH vulnerabilities detected.` | CodeBuild log `phani-devsecops-phase2` |
| **P2-10** | ECS Cluster Overview | [ECS Console](https://ap-south-1.console.aws.amazon.com/ecs/v2/clusters/phani-devsecops-cluster?region=ap-south-1) | Cluster `phani-devsecops-cluster`, Status: **`ACTIVE`** | `aws ecs describe-clusters --clusters phani-devsecops-cluster` |
| **P2-11** | ECS Fargate Service | ECS Cluster Services | Service `payment-api-service`, Launch type: **`FARGATE`**, Desired: 1, Running: 1 | `aws ecs describe-services --cluster phani-devsecops-cluster --services payment-api-service` |
| **P2-12** | ECS Running Task | ECS Cluster Tasks | Task ARN `.../task/...`, status **`RUNNING`**, Container: `payment-api` | `aws ecs list-tasks --cluster phani-devsecops-cluster` |

---

### PHASE 3: Network Security Boundaries & SSM Compliance

| ID | Console Location / Feature | Direct AWS Console URL | What Must Be Visible | Verified CLI Proof |
| :--- | :--- | :--- | :--- | :--- |
| **P3-01** | Customer Managed Prefix List | [VPC Prefix Lists](https://ap-south-1.console.aws.amazon.com/vpc/home?region=ap-south-1#ManagedPrefixLists:) | Prefix list `phani-threat-ips` (`pl-0b2d6049684e69a1a`), Entries: `203.0.113.10/32`, `198.51.100.25/32` | `aws ec2 get-managed-prefix-list-entries --prefix-list-id pl-0b2d6049684e69a1a` |
| **P3-02** | Network Firewall Rule Group | [Network Firewall Console](https://ap-south-1.console.aws.amazon.com/network-firewall/home?region=ap-south-1#/rule-groups) | Rule group `phani-domain-deny-group` (Domain denylist: `example-bad-domain.test`) | `aws network-firewall describe-rule-group --rule-group-name phani-domain-deny-group --type STATEFUL` |
| **P3-03** | Suricata Dynamic IP Drop | Network Firewall Rule Groups | Rule group `phani-ip-drop-group` with Suricata rule: `drop ip @BETA any -> any any (msg:"Dynamic threat drop"; ...)` | `aws network-firewall describe-rule-group --rule-group-name phani-ip-drop-group --type STATEFUL` |
| **P3-04** | Network Firewall Policy | Network Firewall Policies | Policy `phani-firewall-policy` with attached stateful rule groups | `aws network-firewall describe-firewall-policy --firewall-policy-name phani-firewall-policy` |
| **P3-05** | EC2 Runtime Instance | [EC2 Console](https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#Instances:) | Instance `phani-devsecops-runtime` (`i-01ee2623ea4ae8598`), Status: **`Running`**, Type: `t3.micro` | `aws ec2 describe-instances --instance-ids i-01ee2623ea4ae8598` |
| **P3-06** | Systems Manager Fleet Manager | [SSM Fleet Manager](https://ap-south-1.console.aws.amazon.com/systems-manager/managed-instances?region=ap-south-1) | Instance `i-01ee2623ea4ae8598`, Ping status: **`Online`**, Platform: Amazon Linux 2023 | `aws ssm describe-instance-information` |
| **P3-07** | Systems Manager Patch Baseline | [Patch Manager Console](https://ap-south-1.console.aws.amazon.com/systems-manager/patch-manager/baselines?region=ap-south-1) | Baseline `phani-PCI-DSS-LAB-Baseline` (`pb-010d4f6382cb8b315`), Patch Group: `PCI-LAB` | `aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=phani-PCI-DSS-LAB-Baseline"` |
| **P3-08** | Patch Compliance Scan Result | [SSM Run Command History](https://ap-south-1.console.aws.amazon.com/systems-manager/run-command/exec-history?region=ap-south-1) | Document `AWS-RunPatchBaseline` executed on `i-01ee2623ea4ae8598`, Status: **`Success`**, Non-compliant: 0 | `aws ssm list-commands --instance-id i-01ee2623ea4ae8598` |

---

### PHASE 4: Runtime Threat Remediation (SOAR)

| ID | Console Location / Feature | Direct AWS Console URL | What Must Be Visible | Verified CLI Proof |
| :--- | :--- | :--- | :--- | :--- |
| **P4-01** | Amazon GuardDuty Overview | [GuardDuty Console](https://ap-south-1.console.aws.amazon.com/guardduty/home?region=ap-south-1#/dashboard) | GuardDuty detector `5cd0880bc7d3a01b0cd8ab8613f0848a` active in `ap-south-1` | `aws guardduty list-detectors` |
| **P4-02** | GuardDuty Finding Details | GuardDuty Findings List | Finding `Recon:EC2/Portscan` generated and details pane | `aws guardduty list-findings --detector-id 5cd0880bc7d3a01b0cd8ab8613f0848a` |
| **P4-03** | Amazon EventBridge Rule | [EventBridge Rules](https://ap-south-1.console.aws.amazon.com/events/home?region=ap-south-1#/rules) | Rule `guardduty-runtime-response` matching GuardDuty portscan events | `aws events describe-rule --name guardduty-runtime-response` |
| **P4-04** | SOAR Lambda Configuration | [Lambda Console](https://ap-south-1.console.aws.amazon.com/lambda/home?region=ap-south-1#/functions/phani-runtime-soar) | Function `phani-runtime-soar`, environment variables (`TARGET_INSTANCE_ID`, `FORENSIC_BUCKET`, `QUARANTINE_SG_ID`) | `aws lambda get-function --function-name phani-runtime-soar` |
| **P4-05** | SOAR Lambda Execution Logs | [CloudWatch Log Groups](https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fphani-runtime-soar) | Log events showing: finding received, SSM triage triggered, security group swapped | `aws logs get-log-events --log-group-name /aws/lambda/phani-runtime-soar ...` |
| **P4-06** | SSM Run Command Execution | SSM Run Command Details | Command `035139a1-b897-4ee4-be94-5ed0f51d78d9` on `i-01ee2623ea4ae8598`, Status: **`Success`** | `aws ssm get-command-invocation --command-id 035139a1-b897-4ee4-be94-5ed0f51d78d9 --instance-id i-01ee2623ea4ae8598` |
| **P4-07** | Encrypted S3 Forensic Bucket | [S3 Console](https://ap-south-1.console.aws.amazon.com/s3/buckets/phani-fintech-forensics-435023701114?region=ap-south-1) | Bucket `phani-fintech-forensics-435023701114`, Encryption: **`AES-256 (SSE-S3)`** | `aws s3api get-bucket-encryption --bucket phani-fintech-forensics-435023701114` |
| **P4-08** | S3 Public Access Block | S3 Bucket Permissions | All 4 Public Access Block settings: **`ON`** | `aws s3api get-public-access-block --bucket phani-fintech-forensics-435023701114` |
| **P4-09** | Forensic Artifacts in S3 | S3 Bucket Objects | Objects under `incidents/i-01ee2623ea4ae8598/...`: `memory.lime`, `processes.txt`, `sockets.txt`, `triage_summary.json` | `aws s3 ls s3://phani-fintech-forensics-435023701114/incidents/ --recursive` |
| **P4-10** | Quarantined EC2 Security Group | EC2 Instance Details | Security group attached to `i-01ee2623ea4ae8598`: **`phani-quarantine-sg`** (`sg-093142cfb2b569af7`) | `aws ec2 describe-instances --instance-ids i-01ee2623ea4ae8598 --query "Reservations[0].Instances[0].SecurityGroups"` |
| **P4-11** | Quarantine Security Group Rules | [VPC Security Groups](https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#SecurityGroups:) | Group `phani-quarantine-sg`: Inbound = SSH (port 22) only; Outbound = **0 rules (severed)** | `aws ec2 describe-security-groups --group-ids sg-093142cfb2b569af7` |
| **P4-12** | Master CodePipeline 100% Green | CodePipeline Console | Stages Source, IaC Scan, and Container Gate all **`Succeeded`** (All Green) | `aws codepipeline get-pipeline-state --name phani-devsecops-pipeline` |
| **P4-13** | Automated Verification Suite | Terminal Output | Script `bash scripts/verify-all.sh` returning **`[PASS]`** across all 4 phases | `bash scripts/verify-all.sh` |
