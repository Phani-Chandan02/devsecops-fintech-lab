# Cost Management & Resource Optimization Notes

## Objective
Keep AWS expenditures minimal while achieving 100% compliance with lab demonstration requirements.

## Billed Services & Controls

| Service | Cost Driver | Mitigation / Exam Strategy | Post-Exam Action |
| :--- | :--- | :--- | :--- |
| **AWS Network Firewall** | ~$0.395/hr per firewall endpoint | Deploy in **single AZ** only. Test quickly and delete immediately post-exam. | Delete firewall and rule groups |
| **Amazon EC2** | Hourly instance compute | Use single **`t3.micro`** Amazon Linux 2023 instance (free tier eligible). | Terminate instance |
| **Amazon ECS Fargate** | vCPU & GB-memory per second | Minimal container: 0.25 vCPU, 0.5 GB RAM. | Delete cluster and service |
| **Amazon ECR** | Storage ($0.10/GB/month) | Store only 2 demo images (`latest` and base test). | Delete repository |
| **Amazon Inspector** | Metered per container scan | Only scan the `payment-api` repository. | Disable ECR scanning |
| **AWS Secrets Manager** | $0.40/month per secret | Single secret (`fintech/payment-api`). | Delete secret with force |
| **Amazon GuardDuty** | 30-day free trial on new accounts | Generate sample findings (no flow log ingestion cost). | Disable detector if newly enabled |
| **Amazon S3** | Storage & requests | Minimal forensic dumps (<50 MB total). | Empty and delete bucket |
| **CloudWatch Logs** | Ingestion per GB | Set retention to 1 day on lab log groups. | Delete log groups |

## Automated Cleanup
Run `scripts/cleanup.sh` immediately following evaluation.
