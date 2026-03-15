"""Slack notifier Lambda.

Receives SNS messages from ops-alerts and ops-events topics,
formats them into Slack message payloads, and posts to a
configured webhook URL.
"""

from __future__ import annotations

import json
import logging
import os
import urllib.request

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

# Event types that should be posted to Slack
ALERT_EVENTS = {
    "FAILURE",
    "SWEEPER_TIMEOUT",
    "VERSION_MISMATCH",
    "ROLLBACK_FAILED",
    "MANUAL_CANCEL",
}

INFO_EVENTS = {
    "STATE_TRANSITION",
    "SWEEPER_RETRIGGER",
    "ROLLBACK_COMPLETE",
    "MANUAL_RETRY",
    "MANUAL_ADVANCE",
}


def handler(event, context):
    """Process SNS records and post to Slack."""
    if not SLACK_WEBHOOK_URL:
        logger.warning("SLACK_WEBHOOK_URL not configured, skipping")
        return {"statusCode": 200, "skipped": True}

    for record in event.get("Records", []):
        try:
            _process_record(record)
        except Exception:
            logger.exception("Failed to process record")

    return {"statusCode": 200}


def _process_record(record):
    """Parse SNS message and post formatted Slack message."""
    sns = record.get("Sns", {})
    message_str = sns.get("Message", "{}")
    message = json.loads(message_str)

    # Determine event type from message attributes or message body
    attrs = sns.get("MessageAttributes", {})
    event_type = (
        attrs.get("event_type", {}).get("Value", "")
        or message.get("event_type", "UNKNOWN")
    )

    slack_payload = _format_message(event_type, message)
    _post_to_slack(slack_payload)


def _format_message(event_type, message):
    """Format an event into a Slack message payload."""
    op_id = message.get("operation_id", "unknown")
    job_type = message.get("job_type", "unknown")
    timestamp = message.get("timestamp", "")

    if event_type in ALERT_EVENTS:
        color = "#dc3545"  # red
        icon = ":rotating_light:"
    elif event_type in INFO_EVENTS:
        color = "#28a745"  # green
        icon = ":white_check_mark:"
    else:
        color = "#6c757d"  # gray
        icon = ":information_source:"

    # Build fields based on event type
    fields = [
        {"title": "Operation", "value": f"`{op_id}`", "short": True},
        {"title": "Job Type", "value": job_type, "short": True},
    ]

    if "previous_state" in message and "new_state" in message:
        fields.append({
            "title": "Transition",
            "value": (
                f"{message['previous_state'] or 'None'} → "
                f"{message['new_state']}"
            ),
            "short": True,
        })

    if "failed_state" in message:
        fields.append({
            "title": "Failed State",
            "value": message["failed_state"],
            "short": True,
        })

    if "error_message" in message:
        fields.append({
            "title": "Error",
            "value": message["error_message"],
            "short": False,
        })

    if "current_state" in message:
        fields.append({
            "title": "Current State",
            "value": message["current_state"],
            "short": True,
        })

    if "time_since_update_seconds" in message:
        elapsed = message["time_since_update_seconds"]
        fields.append({
            "title": "Elapsed",
            "value": f"{elapsed:.0f}s",
            "short": True,
        })

    return {
        "attachments": [{
            "color": color,
            "fallback": f"{icon} {event_type}: {job_type} {op_id}",
            "title": f"{icon} {event_type}",
            "fields": fields,
            "footer": "detent",
            "ts": timestamp,
        }],
    }


def _post_to_slack(payload):
    """Post a message payload to the Slack webhook."""
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        SLACK_WEBHOOK_URL,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            logger.info("Slack post succeeded: %d", resp.status)
    except Exception:
        logger.exception("Failed to post to Slack")
        raise
