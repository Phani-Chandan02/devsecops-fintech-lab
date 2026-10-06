"""Demo custom rotation Lambda for a non-database secret.
It rotates only the secret value for a lab token. In production, set_secret()
must also update the actual target service/API credential.
"""
import json
import secrets
import string
import boto3

sm = boto3.client("secretsmanager")


def _random_token(length: int = 40) -> str:
    alphabet = string.ascii_letters + string.digits
    return "LAB-" + "".join(secrets.choice(alphabet) for _ in range(length))


def handler(event, context):
    arn = event["SecretId"]
    token = event["ClientRequestToken"]
    step = event["Step"]

    meta = sm.describe_secret(SecretId=arn)
    versions = meta.get("VersionIdsToStages", {})
    if token not in versions:
        raise ValueError("Secret version is not staged for this rotation")

    if step == "createSecret":
        if "AWSPENDING" not in versions[token]:
            current = sm.get_secret_value(SecretId=arn, VersionStage="AWSCURRENT")
            try:
                current_json = json.loads(current["SecretString"])
            except Exception:
                current_json = {"token": current["SecretString"]}
            current_json["token"] = _random_token()
            sm.put_secret_value(
                SecretId=arn,
                ClientRequestToken=token,
                SecretString=json.dumps(current_json),
                VersionStages=["AWSPENDING"],
            )
    elif step == "setSecret":
        # In the real application, update the payment provider here.
        pass
    elif step == "testSecret":
        pending = sm.get_secret_value(SecretId=arn, VersionStage="AWSPENDING", VersionId=token)
        json.loads(pending["SecretString"])
    elif step == "finishSecret":
        current = meta.get("VersionIdsToStages", {})
        current_version = next((v for v, stages in current.items() if "AWSCURRENT" in stages), None)
        if current_version != token:
            sm.update_secret_version_stage(
                SecretId=arn,
                VersionStage="AWSCURRENT",
                MoveToVersionId=token,
                RemoveFromVersionId=current_version,
            )
    else:
        raise ValueError(f"Unknown rotation step: {step}")

    return {"statusCode": 200, "step": step}
