You are helping me finish a 4-hour AWS DevSecOps lab exam.
Create a single GitHub repo called devsecops-fintech-lab with these parts:
1) Terraform demo under app/ with intentionally insecure resources for Checkov testing and a secure fixed version.
2) Dockerfile and tiny payment-api demo.
3) A CodeBuild buildspec that runs Checkov and detect-secrets and returns non-zero on findings.
4) An Inspector gate script that waits for ECR scan completion and blocks when CRITICAL or HIGH counts are greater than zero.
5) Two Lambda functions: Secrets Manager custom rotation handler and GuardDuty -> SSM SOAR handler.
6) EventBridge GuardDuty portscan event pattern.
7) Network Firewall domain deny-list JSON and dynamic prefix-list IP-set-reference rule template.
8) A README containing exact commands and AWS console steps.
Do not add real secrets. Use only dummy/example credentials.
Keep the lab easy to demonstrate in one AWS Region and explain what is production-grade vs intentionally simplified for a time-limited exam.
