#!/usr/bin/env python3
"""
Inspector Automated Deployment Guardrail Gate.
Queries Amazon ECR / Amazon Inspector enhanced vulnerability scan results.
Enforces PCI-DSS v4.0 Requirement 6.4 policy:
Blocks deployment if any HIGH or CRITICAL CVEs are detected.
"""
import os
import sys
import time
import boto3

region = os.environ.get("AWS_DEFAULT_REGION", "ap-south-1")
repo_name = os.environ.get("ECR_REPOSITORY", "payment-api")
image_tag = os.environ.get("IMAGE_TAG", "latest")

print(f"[*] Inspector Guardrail: Evaluating repository '{repo_name}' tag '{image_tag}' in {region}")

ecr = boto3.client("ecr", region_name=region)

print("[*] Waiting for Amazon ECR / Inspector vulnerability scan to complete...")
max_attempts = 30
scan_complete = False

for attempt in range(max_attempts):
    try:
        resp = ecr.describe_image_scan_findings(
            repositoryName=repo_name,
            imageId={"imageTag": image_tag}
        )
        status = resp.get("imageScanStatus", {}).get("status")
        if status == "COMPLETE":
            scan_complete = True
            break
        elif status == "FAILED":
            print(f"[!] Scan failed: {resp.get('imageScanStatus', {}).get('description')}")
            sys.exit(1)
        print(f"    Waiting for scan completion... (status: {status}, attempt {attempt+1}/{max_attempts})")
    except ecr.exceptions.ScanNotFoundException:
        print(f"    Scan pending initiation... (attempt {attempt+1}/{max_attempts})")
    except Exception as e:
        print(f"    Polling scan status: {e}")
    time.sleep(10)

if not scan_complete:
    print("[!] Timed out waiting for scan completion.")
    sys.exit(1)

# Retrieve findings
findings_resp = ecr.describe_image_scan_findings(
    repositoryName=repo_name,
    imageId={"imageTag": image_tag}
)

counts = findings_resp.get("imageScanFindings", {}).get("findingSeverityCounts", {}) or {}
enhanced_findings = findings_resp.get("imageScanFindings", {}).get("enhancedImageScanFindings", [])

# If counts not directly populated in basic format, calculate from enhanced findings
if not counts and enhanced_findings:
    counts = {}
    for f in enhanced_findings:
        sev = f.get("severity", "INFORMATIONAL").upper()
        counts[sev] = counts.get(sev, 0) + 1

# Fallback: check inspector2 client directly if counts still empty
if not counts:
    try:
        insp = boto3.client("inspector2", region_name=region)
        insp_resp = insp.list_findings(
            filterCriteria={
                "ecrImageRepositoryName": [{"comparison": "EQUALS", "value": repo_name}],
                "ecrImageTags": [{"comparison": "EQUALS", "value": image_tag}]
            },
            maxResults=100
        )
        insp_findings = insp_resp.get("findings", [])
        if insp_findings:
            counts = {}
            for f in insp_findings:
                sev = f.get("severity", "INFORMATIONAL").upper()
                counts[sev] = counts.get(sev, 0) + 1
            if not enhanced_findings:
                enhanced_findings = insp_findings
    except Exception as e:
        print(f"[*] Note: Inspector2 API query: {e}")

critical_count = int(counts.get("CRITICAL", 0))
high_count = int(counts.get("HIGH", 0))
medium_count = int(counts.get("MEDIUM", 0))
low_count = int(counts.get("LOW", 0))

print("==========================================================")
print(" AMAZON INSPECTOR VULNERABILITY SCAN SUMMARY")
print("==========================================================")
print(f" REPOSITORY: {repo_name}:{image_tag}")
print(f" CRITICAL:   {critical_count}")
print(f" HIGH:       {high_count}")
print(f" MEDIUM:     {medium_count}")
print(f" LOW:        {low_count}")
print("==========================================================")

# Print top CVE details if present
sample_findings = enhanced_findings[:5] if enhanced_findings else findings_resp.get("imageScanFindings", {}).get("findings", [])[:5]
if sample_findings:
    print("\n[!] Top Identified Vulnerabilities:")
    for f in sample_findings:
        cve_id = f.get("title") or f.get("name") or f.get("findingArn", "CVE")
        sev = f.get("severity", "UNKNOWN")
        desc = f.get("description", "")[:80]
        print(f"  - [{sev}] {cve_id}: {desc}...")

print("")

if critical_count > 0 or high_count > 0:
    print("[!] BLOCK DEPLOYMENT: Policy Violation Detected!")
    print(f"    Found {critical_count} CRITICAL and {high_count} HIGH vulnerabilities.")
    print("    PCI-DSS v4.0 Requirement 6.4 / SOC 2 Type II gate prevents deployment to ECS/EKS.")
    sys.exit(1)
else:
    print("[+] DEPLOYMENT ALLOWED: 0 CRITICAL and 0 HIGH vulnerabilities detected.")
    print("    Container complies with production deployment security baseline.")
    sys.exit(0)

