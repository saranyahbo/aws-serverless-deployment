"""Read and create products/orders through API Gateway proxy events."""

import base64
import binascii
from decimal import Decimal
import json
import logging
import os
from uuid import uuid4

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


def _json_default(value):
    if isinstance(value, Decimal):
        return int(value) if value == value.to_integral_value() else float(value)
    raise TypeError(f"Unsupported JSON type: {type(value).__name__}")


def _response(status, body):
    return {"statusCode": status, "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,Authorization",
                "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
            },
            "body": json.dumps(body, default=_json_default, allow_nan=False)}


def _invalid_number(value):
    raise ValueError("Non-finite numbers are not supported")


def lambda_handler(event, context):
    method = event.get("httpMethod", "").upper()
    proxy_path = (event.get("pathParameters") or {}).get("proxy")
    request_path = proxy_path if proxy_path is not None else event.get("path", "")
    parts = request_path.strip("/").split("/")
    if parts and parts[0] == "clops":
        parts = parts[1:]
    tables = {"products": ("PRODUCTS_TABLE", "productId"),
              "orders": ("ORDERS_TABLE", "orderId")}
    if not parts or parts[0] not in tables or len(parts) > 2:
        return _response(404, {"message": "Resource not found"})
    if method not in {"GET", "POST"}:
        return _response(405, {"message": "Supported methods: GET, POST"})
    collection = parts[0]
    table_env, key = tables[collection]
    table = boto3.resource("dynamodb").Table(os.environ[table_env])
    try:
        if method == "GET":
            if len(parts) == 2:
                item = table.get_item(Key={key: parts[1]}).get("Item")
                return (_response(200, item) if item is not None
                        else _response(404, {"message": "Item not found"}))
            query = event.get("queryStringParameters") or {}
            limit = int(query.get("limit", "25"))
            if not 1 <= limit <= 100:
                raise ValueError("limit must be between 1 and 100")
            scan_args = {"Limit": limit}
            if query.get("nextToken"):
                cursor = json.loads(base64.b64decode(query["nextToken"], validate=True))
                if not isinstance(cursor, dict) or set(cursor) != {key} or not isinstance(cursor[key], str):
                    raise ValueError("Invalid nextToken")
                scan_args["ExclusiveStartKey"] = cursor
            result = table.scan(**scan_args)
            body = {"items": result.get("Items", [])}
            if result.get("LastEvaluatedKey"):
                body["nextToken"] = base64.b64encode(
                    json.dumps(result["LastEvaluatedKey"]).encode()).decode()
            return _response(200, body)

        if len(parts) != 1:
            return _response(405, {"message": "POST requires a collection path"})
        raw_body = event.get("body") or ""
        if event.get("isBase64Encoded"):
            raw_body = base64.b64decode(raw_body, validate=True).decode("utf-8")
        item = json.loads(raw_body, parse_float=Decimal, parse_constant=_invalid_number)
        if not isinstance(item, dict) or not item:
            raise ValueError("Body must be a non-empty JSON object")
        item.setdefault(key, str(uuid4()))
        if not isinstance(item[key], str) or not item[key].strip():
            raise ValueError(f"{key} must be a non-empty string")
        table.put_item(Item=item, ConditionExpression="attribute_not_exists(#pk)",
                       ExpressionAttributeNames={"#pk": key})
        return _response(201, item)
    except (ValueError, TypeError, UnicodeError, binascii.Error):
        return _response(400, {"message": "Invalid JSON, item ID, limit, or pagination token"})
    except ClientError as error:
        code = error.response["Error"]["Code"]
        if code == "ConditionalCheckFailedException":
            return _response(409, {"message": "Item already exists"})
        if code == "ValidationException":
            return _response(400, {"message": "Item does not meet DynamoDB constraints"})
        logger.exception("DynamoDB operation failed")
        raise
