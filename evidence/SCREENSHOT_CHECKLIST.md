# Comprehensive Evidence Screenshot Checklist (40+ Captures)

This checklist specifies the exact console views and CLI proof required by examiners to validate every requirement.

---

### PHASE 1: Shift-Left IaC Security & Secret Governance

| ID | Phase | AWS Console Location | What Must Be Visible | Verification CLI Command |
| :--- | :--- | :--- | :--- | :--- |
| **P1-01** | Phase 1 | GitHub / Repository UI | `devsecops-fintech-lab` repo with `app/`, `terraform/`, `pipeline/` | `git remote -v` |
| **P1-02** | Phase 1 | Developer Tools -> Connections | CodeConnection status (`AVAILABLE`) | `aws codeconnections list-connections` |
| **P1-03** | Phase 1 | CodePipeline Console | Pipeline `fintech-devsecops-pipeline` showing stages | `aws codepipeline get-pipeline-state --name fintech-devsecops-pipeline` |
| **P1-04** | Phase 1 | CodeBuild Console | Project `fintech-devsecops-phase1` configuration | `aws codebuild batch-get-projects --names fintech-devsecops-phase1` |
| **P1-05** | Phase 1 | Source Code / IDE | Vulnerable `terraform/vulnerable/main.tf` (public S3, 0.0.0.0/0 SG) | `cat terraform/vulnerable/main.tf` |
| **P1-06** | Phase 1 | CodeBuild Execution Log | Checkov static scan finding: public S3 bucket & open security group | `checkov -d terraform/vulnerable` |
| **P1-07** | Phase 1 | CodeBuild Execution Log | `detect-secrets` finding: hardcoded API key / token detected | `detect-secrets scan terraform/vulnerable/` |
| **P1-08** | Phase 1 | CodePipeline Console | Red **Failed** stage due to security gate policy failure | `aws codebuild list-builds-for-project --project-name fintech-devsecops-phase1` |
| **P1-09** | Phase 1 | Source Code / IDE | Remediated `terraform/secure/main.tf` with AES256 & private CIDRs | `cat terraform/secure/main.tf` |
| **P1-10** | Phase 1 | CodePipeline Console | Green **Succeeded** stage after pushing secure IaC | `aws codepipeline get-pipeline-state --name fintech-devsecops-pipeline` |
| **P1-11** | Phase 1 | AWS Secrets Manager | Secret `fintech/payment-api` stored with JSON key/value | `aws secretsmanager describe-secret --secret-id fintech/payment-api` |
| **P1-12** | Phase 1 | AWS Lambda Console | Function `fintech-secret-rotation` with 4-stage lifecycle | `aws lambda get-function --function-name fintech-secret-rotation` |
| **P1-13** | Phase 1 | AWS Secrets Manager | Secret Rotation status: **Enabled**, schedule: **rate(30 days)** | `aws secretsmanager describe-secret --secret-id fintech/payment-api --query "RotationRules"` |

---

### PHASE 2: Container Security & Vulnerability Scanning

| ID | Phase | AWS Console Location | What Must Be Visible | Verification CLI Command |
| :--- | :--- | :--- | :--- | :--- |
| **P2-01** | Phase 2 | Amazon ECR Console | Repository `payment-api` in `ap-south-1` | `aws ecr describe-repositories --repository-names payment-api` |
| **P2-02** | Phase 2 | Amazon ECR Images | Tag `latest` pushed with image digest and size | `aws ecr list-images --repository-name payment-api` |
| **P2-03** | Phase 2 | Amazon Inspector / ECR | Enhanced scanning enabled with Amazon Inspector | `aws ecr get-registry-scanning-configuration` |
| **P2-04** | Phase 2 | Amazon Inspector Console | Container image vulnerability scan report | `aws inspector2 list-coverage --filter-criteria '{"ecrImageRepositoryName":[{"comparison":"EQUALS","value":"payment-api"}]}'` |
| **P2-05** | Phase 2 | Amazon ECR Image Scan | Severity counts displaying **CRITICAL > 0** and **HIGH > 0** | `aws ecr describe-image-scan-findings --repository-name payment-api --image-id imageTag=latest` |
| **P2-06** | Phase 2 | CodeBuild / Terminal | Inspector Gate script output: `BLOCK DEPLOY: HIGH/CRITICAL CVEs` | `python phase2/inspector_gate.py` |
| **P2-07** | Phase 2 | CodePipeline Console | Blocked deployment stage preventing image rollout | `aws codepipeline get-pipeline-state --name fintech-devsecops-pipeline` |
| **P2-08** | Phase 2 | Dockerfile / Source Code | Corrected `Dockerfile` with minimal/secure base (`nginx:alpine`) | `cat app/Dockerfile` |
| **P2-09** | Phase 2 | CodeBuild / Terminal | Gate script passing: `DEPLOYMENT ALLOWED: 0 HIGH / 0 CRITICAL` | `python phase2/inspector_gate.py` |
| **P2-10** | Phase 2 | Amazon ECS Console | Cluster `fintech-devsecops-cluster` status ACTIVE | `aws ecs describe-clusters --clusters fintech-devsecops-cluster` |
| **P2-11** | Phase 2 | Amazon ECS Console | Service `payment-api-service` running on Fargate launch type | `aws ecs describe-services --cluster fintech-devsecops-cluster --services payment-api-service` |
| **P2-12** | Phase 2 | Amazon ECS Tasks | Running task with container status `RUNNING` on port 80 | `aws ecs list-tasks --cluster fintech-devsecops-cluster` |

---

### PHASE 3: Network Security Boundaries & SSM Compliance

| ID | Phase | AWS Console Location | What Must Be Visible | Verification CLI Command |
| :--- | :--- | :--- | :--- | :--- |
| **P3-01** | Phase 3 | VPC Console | VPC `devsecops-lab-vpc` with CIDR block | `aws ec2 describe-vpcs --filters "Name=tag:Project,Values=devsecops-fintech-lab"` |
| **P3-02** | Phase 3 | VPC Subnets Console | Workload subnet `devsecops-workload-subnet` | `aws ec2 describe-subnets --filters "Name=tag:Name,Values=*workload*"` |
| **P3-03** | Phase 3 | VPC Subnets Console | Dedicated inspection subnet `devsecops-inspection-subnet` | `aws ec2 describe-subnets --filters "Name=tag:Name,Values=*inspection*"` |
| **P3-04** | Phase 3 | AWS Network Firewall | Firewall `devsecops-lab-network-firewall` status `READY` | `aws network-firewall describe-firewall --firewall-name devsecops-lab-network-firewall` |
| **P3-05** | Phase 3 | Firewall Policy Console | Firewall Policy with stateful rule groups attached | `aws network-firewall describe-firewall-policy --firewall-policy-name fintech-firewall-policy` |
| **P3-06** | Phase 3 | Network Firewall Rules | Stateful domain list rule blocking `example-bad-domain.test` | `aws network-firewall describe-rule-group --rule-group-name fintech-domain-deny-group --type STATEFUL` |
| **P3-07** | Phase 3 | VPC Managed Prefix Lists | Prefix List `devsecops-threat-ips` containing test threat IP | `aws ec2 describe-managed-prefix-lists --filters "Name=prefix-list-name,Values=devsecops-threat-ips"` |
| **P3-08** | Phase 3 | Network Firewall Rules | Suricata DROP rule referencing `@BETA` Prefix List ARN | `aws network-firewall describe-rule-group --rule-group-name fintech-ip-drop-group --type STATEFUL` |
| **P3-09** | Phase 3 | VPC Route Tables | Route pointing outbound traffic toward Network Firewall endpoint | `aws ec2 describe-route-tables --filters "Name=tag:Project,Values=devsecops-fintech-lab"` |
| **P3-10** | Phase 3 | CloudWatch Log Groups | VPC Flow Logs group `/aws/vpc/flowlogs/devsecops-lab` | `aws logs describe-log-groups --log-group-name-prefix /aws/vpc/flowlogs/devsecops-lab` |
| **P3-11** | Phase 3 | Amazon EC2 Console | Instance `devsecops-runtime` running (`t3.micro`) | `aws ec2 describe-instances --filters "Name=tag:Name,Values=devsecops-runtime"` |
| **P3-12** | Phase 3 | Systems Manager Console | EC2 node listed as an **Online Managed Node** | `aws ssm describe-instance-information --query "InstanceInformationList[*].[InstanceId,PingStatus]"` |
| **P3-13** | Phase 3 | Systems Manager Patch Manager | Custom Patch Baseline `PCI-DSS-LAB-Baseline` for AL2023 | `aws ssm describe-patch-baselines --filters "Key=NAME_PREFIX,Values=PCI-DSS-LAB-Baseline"` |
| **P3-14** | Phase 3 | Systems Manager Run Command | Executed `AWS-RunPatchBaseline` scan operation | `aws ssm list-commands --instance-id <INSTANCE_ID>` |
| **P3-15** | Phase 3 | Patch Manager Compliance | Compliance dashboard showing compliance state against baseline | `aws ssm list-compliance-items --resource-ids <INSTANCE_ID> --resource-types ManagedInstance` |

---

### PHASE 4: Runtime Threat Remediation (SOAR)

| ID | Phase | AWS Console Location | What Must Be Visible | Verification CLI Command |
| :--- | :--- | :--- | :--- | :--- |
| **P4-01** | Phase 4 | Amazon GuardDuty Console | GuardDuty detector enabled and active in `ap-south-1` | `aws guardduty list-detectors` |
| **P4-02** | Phase 4 | GuardDuty Findings | Sample finding `Recon:EC2/Portscan` visible in dashboard | `aws guardduty list-findings --detector-id <DETECTOR_ID>` |
| **P4-03** | Phase 4 | Amazon EventBridge Console | Rule `guardduty-runtime-response` matching GuardDuty portscan | `aws events describe-rule --name guardduty-runtime-response` |
| **P4-04** | Phase 4 | AWS Lambda Console | SOAR Function `fintech-runtime-soar` with environment vars | `aws lambda get-function --function-name fintech-runtime-soar` |
| **P4-05** | Phase 4 | CloudWatch Logs Console | Lambda execution log showing incident trigger & triage | `aws logs filter-log-events --log-group-name /aws/lambda/fintech-runtime-soar` |
| **P4-06** | Phase 4 | Systems Manager Run Command | `AWS-RunShellScript` invoked automatically by Lambda | `aws ssm list-commands --filters "Key=DocumentName,Values=AWS-RunShellScript"` |
| **P4-07** | Phase 4 | Run Command Details | Status: **Success**; triage & memory acquisition executed | `aws ssm get-command-invocation --command-id <CMD_ID> --instance-id <INST_ID>` |
| **P4-08** | Phase 4 | Amazon S3 Console | Encrypted Forensic Bucket `fintech-devsecops-forensics-...` | `aws s3api get-bucket-encryption --bucket fintech-devsecops-forensics-<ACCOUNT_ID>` |
| **P4-09** | Phase 4 | Amazon S3 Permissions | Public Access Block **All ON** for forensic bucket | `aws s3api get-public-access-block --bucket fintech-devsecops-forensics-<ACCOUNT_ID>` |
| **P4-10** | Phase 4 | Amazon S3 Objects | Forensic artifacts (`memory.lime`, `sockets.txt`, `processes.txt`) | `aws s3 ls s3://fintech-devsecops-forensics-<ACCOUNT_ID>/incidents/ --recursive` |
| **P4-11** | Phase 4 | EC2 Security Groups | Original Security Group attached prior to incident | `aws ec2 describe-instances --instance-ids <INST_ID> --query "Reservations[0].Instances[0].SecurityGroups"` |
| **P4-12** | Phase 4 | EC2 Security Groups | Replaced Security Group: `devsecops-quarantine-sg` (Isolated) | `aws ec2 describe-instances --instance-ids <INST_ID> --query "Reservations[0].Instances[0].SecurityGroups"` |
| **P4-13** | Phase 4 | Architecture / Summary | Complete closed-loop SOAR automation chain verified | `bash scripts/verify-all.sh` |
