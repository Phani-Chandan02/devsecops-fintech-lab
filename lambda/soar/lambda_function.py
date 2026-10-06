import json
import os
import time
import boto3

ssm = boto3.client("ssm")
ec2 = boto3.client("ec2")

TARGET_INSTANCE_ID = os.environ["TARGET_INSTANCE_ID"]
FORENSIC_BUCKET = os.environ["FORENSIC_BUCKET"]
QUARANTINE_SG_ID = os.environ["QUARANTINE_SG_ID"]


def extract_instance_id(event):
    target = os.environ.get("TARGET_INSTANCE_ID", "").strip()
    try:
        inst_id = event.get("detail", {}).get("resource", {}).get("instanceDetails", {}).get("instanceId", "")
        # GuardDuty sample findings use synthetic IDs like i-99999999 or i-1234567890abcdef0
        if inst_id and not (inst_id.startswith("i-9999") or inst_id.startswith("i-12345")):
            return inst_id
    except Exception:
        pass
    if target:
        return target
    raise ValueError("No valid target instance ID configured or received in event")


def handler(event, context):
    instance_id = extract_instance_id(event)
    key = f"incidents/{instance_id}/{int(time.time())}"

    commands = [
        "set -e",
        "mkdir -p /var/tmp/incident",
        "date -u > /var/tmp/incident/timestamp.txt",
        "uname -a > /var/tmp/incident/uname.txt 2>&1 || true",
        "id > /var/tmp/incident/id.txt 2>&1 || true",
        "ip addr > /var/tmp/incident/ip.txt 2>&1 || true",
        "ip route > /var/tmp/incident/routes.txt 2>&1 || true",
        "ss -tupn > /var/tmp/incident/sockets.txt 2>&1 || true",
        "ps auxww > /var/tmp/incident/processes.txt 2>&1 || true",
        "curl -L -o /var/tmp/incident/avml https://github.com/microsoft/avml/releases/latest/download/avml",
        "chmod 700 /var/tmp/incident/avml",
        "/var/tmp/incident/avml /var/tmp/incident/memory.lime || echo 'AVML failed (possible kernel lockdown or unsupported memory source)' > /var/tmp/incident/avml_error.txt",
        f"aws s3 cp /var/tmp/incident/ s3://{FORENSIC_BUCKET}/{key}/ --recursive --sse AES256",
    ]

    resp = ssm.send_command(
        DocumentName="AWS-RunShellScript",
        InstanceIds=[instance_id],
        Comment="Automated forensic collection before quarantine",
        Parameters={"commands": commands},
        TimeoutSeconds=600,
    )
    command_id = resp["Command"]["CommandId"]

    status = "Pending"
    for _ in range(60):
        time.sleep(10)
        inv = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
        status = inv["Status"]
        if status in {"Success", "Failed", "Cancelled", "TimedOut", "Undeliverable"}:
            break

    if status != "Success":
        raise RuntimeError(f"Forensic SSM command ended with status: {status}")

    # Quarantine after collection/upload so the host still has the network path needed for S3/SSM.
    ec2.modify_instance_attribute(InstanceId=instance_id, Groups=[QUARANTINE_SG_ID])

    return {
        "instanceId": instance_id,
        "ssmCommandId": command_id,
        "forensicPrefix": f"s3://{FORENSIC_BUCKET}/{key}/",
        "quarantineSecurityGroup": QUARANTINE_SG_ID,
        "action": "forensic-collection-complete-and-host-quarantined",
    }
