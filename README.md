# 4-Hour AWS DevSecOps Lab Exam Kit

## Recommended lab architecture

GitHub -> CodePipeline -> CodeBuild (Checkov + detect-secrets) -> Docker build -> ECR Enhanced Scanning (Amazon Inspector) -> Inspector gate -> ECS (Fargate) deployment

Secrets Manager -> custom Lambda rotation -> 30-day schedule

EC2 managed node -> SSM Patch Manager -> compliance

GuardDuty -> EventBridge -> SOAR Lambda -> SSM Run Command -> forensic collection to encrypted S3 -> quarantine security group

## Fast strategy

Use AWS CloudShell in ONE region for the whole lab (recommended: ap-south-1). Use the AWS console only for the few resources that are faster interactively: GitHub CodeConnections, CodePipeline wizard, Secrets Manager rotation association, Network Firewall routing, and viewing evidence.

Do not create an EKS cluster during a 4-hour exam unless the examiner explicitly requires it. ECS/Fargate satisfies the statement's "EKS or ECS" deployment target and is much faster to demonstrate. Use an EC2 instance for the runtime compromise/SSM part because it gives a real Systems Manager managed node.

## Safety / cost

This lab creates billable resources, especially Network Firewall, NAT Gateway, EC2, ECS Fargate, ECR/Inspector, and KMS. Delete everything after the exam.

## Order

1. Bootstrap repo files and verify AWS CLI identity.
2. Create ECR repository; enable Inspector ECR scanning; build/push vulnerable image.
3. Create CodeBuild project with `pipeline/buildspec.yml` and connect it to CodePipeline.
4. Create Secrets Manager secret + Lambda rotation + 30-day schedule.
5. Create one SSM-managed EC2 node; configure Patch Manager and scan compliance.
6. Create Network Firewall + domain deny rule + dynamic IP block using customer-managed prefix list.
7. Create encrypted S3 forensic bucket + SOAR Lambda + EventBridge GuardDuty rule.
8. Generate GuardDuty sample finding, verify Lambda executed, SSM command succeeded, memory artifact/report landed in S3, and instance was quarantined.
9. Capture screenshots from each service and clean up.

## Key evidence screenshots

- CodePipeline: failed IaC security gate and then passing gate after remediation.
- CodeBuild logs showing Checkov + detect-secrets.
- Secrets Manager: rotation enabled, `rate(30 days)` visible, Lambda rotation function attached.
- ECR: Enhanced scanning enabled; Inspector findings showing HIGH/CRITICAL counts.
- Guardrail logs: deployment gate blocked when HIGH/CRITICAL > 0.
- Patch Manager: node + baseline + compliance result.
- Network Firewall: firewall endpoint in inspection subnet, stateful domain deny rule, prefix-list IP block reference.
- GuardDuty: finding + EventBridge rule + Lambda logs.
- SSM Run Command: command success.
- S3: encrypted forensic object.
- EC2: security group changed to quarantine SG.

## Important lab note

GuardDuty sample findings use placeholder/fictitious finding details. The SOAR Lambda in this kit supports a fixed `TARGET_INSTANCE_ID` fallback so the demo works reliably. In a production implementation, the Lambda should always extract the real instance ID from the GuardDuty finding event.
