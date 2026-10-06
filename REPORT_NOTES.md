# Academic Lab Exam Report Notes: Automated DevSecOps Pipeline & Security Compliance

## 1. Introduction
This project provides an automated DevSecOps and Cloud Security compliance pipeline tailored for a cloud-native fintech payment processing workload on AWS. The design implements preventative, detective, and responsive security controls aligned with **PCI-DSS v4.0** and **SOC 2 Type II** frameworks.

## 2. Problem Statement
Fintech workloads face stringent compliance obligations regarding payment card data protection, continuous patch management, boundary protection, and runtime incident isolation. The challenge was to eliminate delayed manual security reviews by embedding automated gates into Infrastructure-as-Code (IaC), container packaging, network boundaries, and host-level threat isolation.

## 3. Solution Overview
The implementation is partitioned across four operational phases:
1. **Phase 1: Shift-Left IaC Security & Secret Governance**
   - Pre-deployment static analysis using Checkov.
   - Pre-commit secret scanning via `detect-secrets`.
   - Secret centralization and automated 30-day rotation via AWS Secrets Manager and AWS Lambda.
2. **Phase 2: Container Security & Vulnerability Scanning**
   - ECR Enhanced Scanning powered by Amazon Inspector.
   - Automated deployment gate script blocking releases with HIGH or CRITICAL CVEs.
   - Controlled deployment to Amazon ECS Fargate.
3. **Phase 3: Network Security Boundaries & Systems Manager Compliance**
   - AWS Network Firewall with stateful HTTP/TLS domain filtering.
   - Dynamic IP blocking using a Customer-Managed Prefix List and Suricata rules.
   - AWS Systems Manager Patch Manager compliance auditing against a custom PCI-DSS baseline.
4. **Phase 4: Runtime Threat Remediation (SOAR Framework)**
   - Amazon GuardDuty detection of anomalous egress / portscan activity.
   - Amazon EventBridge triggering a serverless SOAR AWS Lambda function.
   - Systems Manager Run Command automating live host triage and AVML memory dump acquisition to an encrypted S3 bucket.
   - Dynamic host quarantine via Security Group reassignment.

## 4. Compliance Framework Alignment
*Note: This architecture demonstrates security controls aligned to PCI-DSS v4.0 and SOC 2 Type II objectives within a lab demonstration context. Formal compliance requires third-party Qualified Security Assessor (QSA) certification.*

- **PCI-DSS Requirement 1.2 / 1.3**: Network boundary defense implemented via AWS Network Firewall in an isolated inspection subnet.
- **PCI-DSS Requirement 6.3**: Secure software development lifecycle enforced via Checkov static analysis in AWS CodePipeline.
- **PCI-DSS Requirement 6.4**: Vulnerability management enforced via Inspector ECR scanning and automated build blocking.
- **PCI-DSS Requirement 8.6**: Secret storage and cryptographic key management enforced via AWS Secrets Manager with 30-day rotation.
- **PCI-DSS Requirement 10.4 & 12.10**: Continuous runtime intrusion detection and automated incident response via GuardDuty, EventBridge, Lambda, and Systems Manager.
- **SOC 2 Type II (Common Criteria 6.1, 6.6, 7.1, 7.2, 7.3)**: Logical access control, perimeter boundary filtering, change management gates, runtime anomaly detection, and automated containment.

## 5. Limitations & Future Scope
- **Memory Dump on Modern Linux**: AVML requires access to `/dev/crash` or `/proc/kcore`. If kernel lockdown is enforced by the operating system kernel, userland memory capture logs the constraint while maintaining non-volatile forensic triage artifacts (processes, sockets, routes, filesystem logs).
- **Production Architecture**: A production enterprise deployment would employ multi-AZ Network Firewalls with Transit Gateway inspection, centralized Security Hub aggregation, KMS Customer Managed Keys (CMKs) with key rotation, and dedicated forensic analysis accounts.
