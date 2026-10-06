# Architecture Specification: DevSecOps & Cloud Security Compliance

## Overview
This architecture implements an end-to-end Automated Security Pipeline and Runtime Threat Detection & Remediation Framework for an API-driven fintech payment platform on AWS. The design aligns with **PCI-DSS v4.0** and **SOC 2 Type II** trust services criteria.

```
+---------------------------------------------------------------------------------------------------------+
|                                    AWS REGION: ap-south-1 (Mumbai)                                       |
+---------------------------------------------------------------------------------------------------------+

  PHASE 1: SHIFT-LEFT IaC SECURITY & SECRET GOVERNANCE
  ----------------------------------------------------
  Developer Git Push ---> GitHub (devsecops-fintech-lab)
                              |
                              v
                      AWS CodePipeline
                              |
                              v
                      AWS CodeBuild (Phase 1)
                      +------------------------------------------+
                      | 1. Checkov: Terraform IaC Static Scan    |  FAIL on open S3, public SG
                      | 2. detect-secrets: Secret Governance     |  FAIL on hardcoded credentials
                      +------------------------------------------+
                              | PASS
                              v
  AWS Secrets Manager: fintech/payment-api <---> AWS Lambda: fintech-secret-rotation (rate 30 days)

  PHASE 2: CONTAINER SECURITY & VULNERABILITY GUARDRAILS
  ------------------------------------------------------
  Docker Build ---> Amazon ECR (payment-api)
                         |
                         v
              Amazon Inspector (Enhanced Scanning on push)
                         |
                         v
              Inspector Deployment Gate (inspector_gate.py)
              +------------------------------------------+
              | Evaluates CVE severities                 |
              | CRITICAL > 0 OR HIGH > 0 ---> BLOCK      |
              +------------------------------------------+
                         | PASS (0 HIGH, 0 CRITICAL)
                         v
              Amazon ECS / Fargate (fintech-devsecops-cluster)

  PHASE 3: NETWORK BOUNDARIES & SSM COMPLIANCE
  --------------------------------------------
  VPC (devsecops-lab-vpc)
    +-- Workload Subnet (EC2 / ECS Tasks)
    +-- Dedicated Inspection Subnet
              |
              v
      AWS Network Firewall (devsecops-lab-network-firewall)
        |-- Stateful Domain Filter (example-bad-domain.test -> DENY)
        +-- Suricata Dynamic IP Drop (Customer Prefix List: devsecops-threat-ips)

  SSM Patch Manager:
    EC2 Node (devsecops-runtime, PatchGroup=PCI-LAB) <---> Custom Patch Baseline (PCI-DSS-LAB-Baseline)

  PHASE 4: RUNTIME THREAT REMEDIATION (SOAR)
  ------------------------------------------
  Compromised Workload (Anomalous Portscan Activity)
             |
             v
  Amazon GuardDuty (Finding: Recon:EC2/Portscan) + VPC Flow Logs
             |
             v
  Amazon EventBridge Rule (guardduty-runtime-response)
             |
             v
  AWS Lambda SOAR Function (fintech-runtime-soar)
             |
             +---> AWS Systems Manager (SSM) Run Command (AWS-RunShellScript)
             |        |-- Volatile memory triage & capture (AVML)
             |        |-- System sockets, processes, routes, network triage
             |        +-- Upload to Encrypted S3 Bucket (SSE-AES256)
             |
             +---> Quarantine Host (Replace Security Group -> devsecops-quarantine-sg)
```

## Security Control Mapping

| Lifecycle Stage | Control Implementation | PCI-DSS v4.0 Mapping | SOC 2 Type II Mapping |
| :--- | :--- | :--- | :--- |
| **IaC Pre-Commit** | Checkov Terraform static analysis | Req 6.3 (Security in Software Dev) | CC7.1 (Change Management) |
| **Secret Governance** | `detect-secrets` + Secrets Manager + 30-day rotation | Req 8.2 / 8.6 (Auth & Credentials) | CC6.1 / CC6.2 (Access Control) |
| **Container Scanning** | Amazon Inspector Enhanced Scanning on ECR | Req 6.4 (Vulnerability Management) | CC7.1 (Vulnerability Detection) |
| **Deployment Guardrail**| CodeBuild Inspector Gate script | Req 6.4.2 (Remediation before release)| CC8.1 (Change Authorization) |
| **Perimeter Inspection**| AWS Network Firewall stateful domain & IP filter | Req 1.2 / 1.3 (Network Perimeter) | CC6.6 (Boundary Protection) |
| **Patch Management** | SSM Patch Manager with PCI baseline | Req 6.3.3 (Security Patching) | CC7.1 (System Maintenance) |
| **Runtime Detection** | Amazon GuardDuty & VPC Flow Logs | Req 10.4 / 11.4 (Threat Detection) | CC7.2 (Security Monitoring) |
| **Incident Response** | EventBridge + Lambda SOAR + SSM Quarantine | Req 12.10 (Incident Response) | CC7.3 / CC7.4 (Incident Handling)|
| **Forensic Storage** | Encrypted S3 Bucket (SSE-AES256, Public Block) | Req 10.5 (Audit Trail Protection) | CC6.5 (Data Protection) |
