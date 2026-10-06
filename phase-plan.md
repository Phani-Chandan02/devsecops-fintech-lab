# 4-hour execution plan

| Time | What you actually do | What you show |
|---|---|---|
| 0:00-0:15 | CloudShell, region, S3 artifact/source buckets if needed, repo upload | Repo + AWS identity |
| 0:15-1:00 | Phase 1: CodeBuild Checkov + detect-secrets; connect CodePipeline | Failed -> fixed -> passed pipeline |
| 1:00-1:35 | Secrets Manager + rotation Lambda + 30-day schedule | Secret + Lambda + schedule |
| 1:35-2:20 | ECR + Inspector + vulnerable image + gate | Findings + BLOCK DEPLOY |
| 2:20-3:00 | ECS target + SSM EC2 + Patch Manager | ECS + patch compliance |
| 3:00-3:30 | Network Firewall domain deny + dynamic IP prefix list + route | Firewall policy/rules |
| 3:30-4:00 | GuardDuty -> EventBridge -> Lambda -> SSM -> S3 + quarantine | Finding + run command + S3 + changed SG |

If time slips: finish the evidence for all four phases before polishing deployments. The score is usually helped more by proving each required control than by building a full production-grade app.
