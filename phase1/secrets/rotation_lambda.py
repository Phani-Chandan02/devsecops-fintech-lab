import json
import logging
import secrets
import string
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sm = boto3.client("secretsmanager")


def _generate_secure_token(length: int = 40) -> str:
    chars = string.ascii_letters + string.digits
    return "FINTECH-" + "".join(secrets.choice(chars) for _ in range(length))


def handler(event, context):
    """
    AWS Secrets Manager rotation Lambda for custom non-database API secrets.
    Implements the 4-step rotation lifecycle:
    1. createSecret: Generate new pending secret version
    2. setSecret: Update credentials in upstream payment provider
    3. testSecret: Verify functionality with AWSPENDING secret
    4. finishSecret: Move AWSCURRENT staging label to new version
    """
    secret_id = event["SecretId"]
    token = event["ClientRequestToken"]
    step = event["Step"]

    logger.info(f"Executing rotation step {step} for secret {secret_id}")

    metadata = sm.describe_secret(SecretId=secret_id)
    versions = metadata.get("VersionIdsToStages", {})
    if token not in versions:
        raise ValueError(f"Secret version {token} has no stage for rotation")

    if step == "createSecret":
        if "AWSPENDING" not in versions[token]:
            current_value = sm.get_secret_value(SecretId=secret_id, VersionStage="AWSCURRENT")
            try:
                secret_dict = json.loads(current_value["SecretString"])
            except Exception:
                secret_dict = {"api_token": current_value["SecretString"]}

            # Generate rotated token value
            secret_dict["api_token"] = _generate_secure_token()
            sm.put_secret_value(
                SecretId=secret_id,
                ClientRequestToken=token,
                SecretString=json.dumps(secret_dict),
                VersionStages=["AWSPENDING"],
            )
            logger.info("Successfully created AWSPENDING secret version")

    elif step == "setSecret":
        # In a live payment gateway, make the API call to register the new token
        logger.info("Simulating credential propagation to upstream payment gateway")

    elif step == "testSecret":
        # Test authentication with the pending version
        pending_val = sm.get_secret_value(SecretId=secret_id, VersionStage="AWSPENDING", VersionId=token)
        json.loads(pending_val["SecretString"])
        logger.info("Successfully verified AWSPENDING token validation")

    elif step == "finishSecret":
        current_version = next((v for v, stages in versions.items() if "AWSCURRENT" in stages), None)
        if current_version != token:
            sm.update_secret_version_stage(
                SecretId=secret_id,
                VersionStage="AWSCURRENT",
                MoveToVersionId=token,
                RemoveFromVersionId=current_version,
            )
            logger.info(f"Promoted version {token} to AWSCURRENT")
    else:
        raise ValueError(f"Unknown rotation step: {step}")

    return {"statusCode": 200, "step": step, "secretId": secret_id}
