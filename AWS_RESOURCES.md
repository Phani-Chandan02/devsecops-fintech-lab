# AWS Deployed Resources Inventory

**Candidate**: `phani`  
**AWS Account ID**: `435023701114`  
**IAM Identity**: `arn:aws:iam::435023701114:user/phani-cli`  
**Region**: `ap-south-1` (Mumbai)  
**Project**: `devsecops-fintech-lab`  
**GitHub Repo**: `https://github.com/Phani-Chandan02/devsecops-fintech-lab`  

---

| Phase | Category | Resource Name / ID | ARN / Identifier | Status / Details |
| :--- | :--- | :--- | :--- | :--- |
| **P1** | Source Control Connection | `devsecops-fintech-connection` | `arn:aws:codeconnections:ap-south-1:435023701114:connection/1958f30d-2ec2-4ae0-b5c9-59add21bdb4f` | **AVAILABLE** (GitHub authorized) |
| **P1** | S3 Artifact Storage | `phani-codepipeline-artifacts-435023701114` | `arn:aws:s3:::phani-codepipeline-artifacts-435023701114` | Active (AES-256 encrypted) |
| **P1** | CodeBuild (IaC & Secrets) | `phani-devsecops-phase1` | `arn:aws:codebuild:ap-south-1:435023701114:project/phani-devsecops-phase1` | Active (Checkov + detect-secrets) |
| **P1** | CodePipeline (CI/CD) | `phani-devsecops-pipeline` | `arn:aws:codepipeline:ap-south-1:435023701114:phani-devsecops-pipeline` | Active (3-Stage Security Pipeline) |
| **P1** | Secrets Manager | `phani/fintech/payment-api` | `arn:aws:secretsmanager:ap-south-1:435023701114:secret:phani/fintech/payment-api-0k5W1T` | Active (JSON credentials stored) |
| **P1** | Secret Rotation Lambda | `phani-secret-rotation` | `arn:aws:lambda:ap-south-1:435023701114:function:phani-secret-rotation` | Active (4-stage rotation lifecycle) |
| **P1** | Rotation Schedule | `rate(30 days)` | `RotationEnabled: true` | Enforcing PCI-DSS v4.0 Req 8.6 |
| **P2** | ECR Repository | `payment-api` & `phani-payment-api` | `435023701114.dkr.ecr.ap-south-1.amazonaws.com/payment-api` | `scanOnPush=true` |
| **P2** | Amazon Inspector v2 | ECR Enhanced Scanning | `scanType: ENHANCED`, `scanFrequency: SCAN_ON_PUSH` | Active (Automated CVE detection) |
| **P2** | CodeBuild (Containers) | `phani-devsecops-phase2` | `arn:aws:codebuild:ap-south-1:435023701114:project/phani-devsecops-phase2` | Active (Build, push, Inspector gate) |
| **P2** | ECS Cluster | `phani-devsecops-cluster` | `arn:aws:ecs:ap-south-1:435023701114:cluster/phani-devsecops-cluster` | Status: `ACTIVE` |
| **P2** | ECS Task Definition | `payment-api:1` | `arn:aws:ecs:ap-south-1:435023701114:task-definition/payment-api:1` | Active (Fargate launch type, 256/512) |
| **P3** | Managed Prefix List | `phani-threat-ips` | `pl-0b2d6049684e69a1a` | Active (`203.0.113.10/32`, `198.51.100.25/32`) |
| **P3** | Firewall Rule Group | `phani-domain-deny-group` | `arn:aws:network-firewall:ap-south-1:435023701114:stateful-rulegroup/phani-domain-deny-group` | Active (Domain denylist) |
| **P3** | Firewall Rule Group | `phani-ip-drop-group` | `arn:aws:network-firewall:ap-south-1:435023701114:stateful-rulegroup/phani-ip-drop-group` | Active (Suricata dynamic drop `@BETA`) |
| **P3** | Firewall Policy | `phani-firewall-policy` | `arn:aws:network-firewall:ap-south-1:435023701114:firewall-policy/phani-firewall-policy` | Active |
| **P3** | EC2 Runtime Instance | `phani-devsecops-runtime` | `i-01ee2623ea4ae8598` | Running (`t3.micro`, Amazon Linux 2023) |
| **P3** | SSM Managed Node | `i-01ee2623ea4ae8598` | `PingStatus: Online` | Attached Role: `phani-ec2-ssm-role` |
| **P3** | SSM Patch Baseline | `phani-PCI-DSS-LAB-Baseline` | `pb-010d4f6382cb8b315` | Default for `PatchGroup=PCI-LAB` |
| **P3** | SSM Run Command | `AWS-RunPatchBaseline` | Status: `Success` | 0 Critical Non-Compliant |
| **P4** | Amazon GuardDuty | Detector | `5cd0880bc7d3a01b0cd8ab8613f0848a` | Active in `ap-south-1` |
| **P4** | EventBridge Rule | `guardduty-runtime-response` | `arn:aws:events:ap-south-1:435023701114:rule/guardduty-runtime-response` | Filter: `Recon:EC2/Portscan` |
| **P4** | SOAR Remediation Lambda | `phani-runtime-soar` | `arn:aws:lambda:ap-south-1:435023701114:function:phani-runtime-soar` | Automated SSM Triage + Isolation |
| **P4** | Quarantine Security Group | `phani-quarantine-sg` | `sg-093142cfb2b569af7` | Ingress: SSH (port 22) only; Egress: 0 rules |
| **P4** | Encrypted S3 Bucket | `phani-fintech-forensics-435023701114` | `arn:aws:s3:::phani-fintech-forensics-435023701114` | SSE-S3 AES-256, Public Access Blocked |
| **P4** | Forensic Artifacts | Evidence in S3 | `s3://phani-fintech-forensics-435023701114/incidents/i-01ee2623ea4ae8598/` | 10 files (memory dump, sockets, ps) |
