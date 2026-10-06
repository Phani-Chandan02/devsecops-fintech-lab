# Examiner Evidence Checklist

## Phase 1
- [ ] GitHub repository visible
- [ ] CodePipeline source -> CodeBuild stage visible
- [ ] Checkov output contains FAIL for public S3 / open SG
- [ ] detect-secrets finds dummy token and build fails
- [ ] Secure commit passes
- [ ] Secrets Manager secret exists
- [ ] Lambda rotation function attached
- [ ] Rotation schedule shows `rate(30 days)`

## Phase 2
- [ ] ECR repository visible
- [ ] Enhanced scanning / Amazon Inspector visible
- [ ] Image pushed
- [ ] Inspector HIGH/CRITICAL findings visible
- [ ] Gate output says `BLOCK DEPLOY`
- [ ] After image remediation, gate can say `DEPLOYMENT ALLOWED`
- [ ] ECS service/task uses only an approved image (Fargate)

## Phase 3
- [ ] VPC with dedicated inspection subnet
- [ ] Network Firewall endpoint / status available
- [ ] Stateful domain deny rule
- [ ] Customer-managed prefix list with malicious-test IP/CIDR
- [ ] Suricata rule uses an IP set reference
- [ ] Patch baseline named for PCI-style lab compliance
- [ ] EC2 managed node shows SSM managed status
- [ ] Patch compliance report visible

## Phase 4
- [ ] GuardDuty detector enabled
- [ ] EventBridge rule pattern for `Recon:EC2/Portscan`
- [ ] SOAR Lambda target configured
- [ ] GuardDuty sample finding generated
- [ ] Lambda logs show incident response started
- [ ] SSM Run Command successful
- [ ] S3 forensic folder/object exists and is encrypted
- [ ] EC2 SG changed to quarantine SG
