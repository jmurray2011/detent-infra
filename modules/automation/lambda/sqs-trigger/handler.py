"""SQS-to-Jenkins trigger Lambda.

Receives SQS messages from the watcher-trigger queue, extracts the
operation ID and job type, and invokes the appropriate Watcher Jenkins
job via the Jenkins API.
"""

from __future__ import annotations

import json
import logging
import os
import urllib.request
import urllib.error
import base64

logger = logging.getLogger()
logger.setLevel(logging.INFO)

JENKINS_URL = os.environ.get("JENKINS_URL", "http://jenkins:8080")
JENKINS_USER = os.environ.get("JENKINS_USER", "admin")
JENKINS_TOKEN = os.environ.get("JENKINS_TOKEN", "admin")

# Maps job_type to Jenkins job path
JOB_ROUTES = json.loads(os.environ.get("JOB_ROUTES", "{}"))


def handler(event, context):
    """Process SQS messages and trigger Jenkins Watcher jobs."""
    for record in event.get("Records", []):
        try:
            _process_record(record)
        except Exception:
            logger.exception("Failed to process record: %s", record)
            raise  # Let SQS retry / DLQ handle it

    return {"statusCode": 200, "processed": len(event.get("Records", []))}


def _process_record(record):
    """Extract operation info and trigger Jenkins."""
    body = json.loads(record["body"])

    # SNS wraps the message in a Message field
    if "Message" in body:
        message = json.loads(body["Message"])
    else:
        message = body

    operation_id = message.get("operation_id", "")
    job_type = message.get("job_type", "")

    if not operation_id or not job_type:
        logger.warning("Missing operation_id or job_type in message: %s", body)
        return

    jenkins_job = JOB_ROUTES.get(job_type)
    if not jenkins_job:
        logger.warning("No Jenkins job route for job_type: %s", job_type)
        return

    _trigger_jenkins(jenkins_job, operation_id)


def _trigger_jenkins(job_path, operation_id):
    """Call the Jenkins API to trigger a parameterized build."""
    url = (
        f"{JENKINS_URL}/job/{job_path}/buildWithParameters"
        f"?OPERATION_ID={operation_id}"
    )

    auth = base64.b64encode(
        f"{JENKINS_USER}:{JENKINS_TOKEN}".encode()
    ).decode()

    req = urllib.request.Request(
        url,
        method="POST",
        headers={"Authorization": f"Basic {auth}"},
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            logger.info(
                "Triggered %s for operation %s (status=%d)",
                job_path, operation_id, resp.status,
            )
    except urllib.error.HTTPError as exc:
        logger.error(
            "Jenkins API error triggering %s: %d %s",
            job_path, exc.code, exc.reason,
        )
        raise
