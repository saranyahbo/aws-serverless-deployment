"""Record SNS deliveries in CloudWatch without republishing to the source topic."""

import json
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    records = event.get("Records")
    if not isinstance(records, list) or not records:
        raise ValueError("Expected an SNS event with Records")
    for record in records:
        if record.get("EventSource") != "aws:sns":
            raise ValueError("Only SNS records are supported")
        notification = record["Sns"]
        # Log one JSON object so arbitrary message text cannot forge log lines.
        logger.info(json.dumps({
            "messageId": notification["MessageId"],
            "topicArn": notification["TopicArn"],
            "subject": notification.get("Subject"),
            "message": notification["Message"],
        }))
    return {"processed": len(records)}
