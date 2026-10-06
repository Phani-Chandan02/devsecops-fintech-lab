# AWS Deployed Resources Inventory

**Region**: `ap-south-1`  
**Account ID**: `435023701114`  
**Owner / Project**: `devsecops-fintech-lab`

| Resource Category | Logical Name | Resource Name / ID | ARN / Details | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Identity & Account** | AWS CLI User | `phani-cli` | `arn:aws:iam::435023701114:user/phani-cli` | Active |
| **Pipeline (P1)** | CodeConnections | `devsecops-fintech-connection` | `arn:aws:codeconnections:ap-south-1:435023701114:connection/1958f30d-2ec2-4ae0-b5c9-59add21bdb4f` | PENDING Authorization |
| **Pipeline (P1)** | CodeBuild Phase 1 | `fintech-devsecops-phase1` | `arn:aws:codebuild:ap-south-1:435023701114:project/fintech-devsecops-phase1` | - |
| **Pipeline (P1)** | CodePipeline | `fintech-devsecops-pipeline` | `arn:aws:codepipeline:ap-south-1:435023701114:fintech-devsecops-pipeline` | - |
| **Secrets (P1)** | Secrets Manager | `fintech/payment-api` | `arn:aws:secretsmanager:ap-south-1:435023701114:secret:fintech/payment-api` | - |
| **Secrets (P1)** | Rotation Lambda | `fintech-secret-rotation` | `arn:aws:lambda:ap-south-1:435023701114:function:fintech-secret-rotation` | - |
| **Container (P2)** | ECR Repository | `payment-api` | `435023701114.dkr.ecr.ap-south-1.amazonaws.com/payment-api` | - |
| **Container (P2)** | Amazon Inspector | ECR Enhanced Scan | Enabled (`ap-south-1`) | - |
| **Container (P2)** | ECS Cluster | `fintech-devsecops-cluster` | `arn:aws:ecs:ap-south-1:435023701114:cluster/fintech-devsecops-cluster` | - |
| **Container (P2)** | ECS Fargate Service | `payment-api-service` | `payment-api` | - |
| **Network (P3)** | VPC | `devsecops-lab-vpc` | *(configured in setup)* | - |
| **Network (P3)** | Inspection Subnet | `devsecops-inspection-subnet` | *(configured in setup)* | - |
| **Network (P3)** | Network Firewall | `devsecops-lab-network-firewall` | *(configured in setup)* | - |
| **Network (P3)** | Prefix List | `devsecops-threat-ips` | `203.0.113.10/32` | - |
| **Compliance (P3)** | SSM EC2 Node | `devsecops-runtime` | `t3.micro` Amazon Linux 2023 | - |
| **Compliance (P3)** | Patch Baseline | `PCI-DSS-LAB-Baseline` | Lab PCI baseline (Security / Critical & Important) | - |
| **Runtime (P4)** | GuardDuty Detector | Default Detector | *(queried via CLI)* | - |
| **Runtime (P4)** | EventBridge Rule | `guardduty-runtime-response` | `Recon:EC2/Portscan` filter | - |
| **Runtime (P4)** | SOAR Lambda | `fintech-runtime-soar` | `arn:aws:lambda:ap-south-1:435023701114:function:fintech-runtime-soar` | - |
| **Runtime (P4)** | Quarantine SG | `devsecops-quarantine-sg` | Ingress: SSH management only; Egress: 0 | - |
| **Runtime (P4)** | Forensic S3 Bucket | `fintech-devsecops-forensics-435023701114` | SSE-S3 AES256, Public Access Blocked | - |
