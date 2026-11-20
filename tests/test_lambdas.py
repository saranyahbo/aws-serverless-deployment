"""Exercise handler behavior without AWS credentials or live Okta calls."""

import base64
from decimal import Decimal
import importlib.util
import io
import json
import os
from pathlib import Path
import time
import unittest
from unittest.mock import MagicMock, patch
from urllib.error import URLError

from botocore.exceptions import ClientError


def load_handler(name):
    path = Path(__file__).resolve().parents[1] / "lambdas" / name / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


auth = load_handler("okta_auth")
backend = load_handler("backend_function")
sns = load_handler("sns_notification_function")


class AuthorizerTests(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, {
            "OKTA_ISSUER": "https://example.okta.com/oauth2/default",
            "OKTA_AUDIENCE": "api://default", "OKTA_CLIENT_ID": "client",
            "OKTA_CLIENT_SECRET": "secret",
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.event = {"authorizationToken": "Bearer access-token",
                      "methodArn": "arn:aws:execute-api:us-east-1:123:api/stage/GET/clops/products"}
        self.claims = {"active": True, "iss": os.environ["OKTA_ISSUER"],
                       "aud": "api://default", "sub": "user-1", "exp": time.time() + 60}

    def introspection(self, claims):
        response = MagicMock()
        response.__enter__.return_value = io.StringIO(json.dumps(claims))
        return patch.object(auth, "urlopen", return_value=response)

    def test_valid_token_returns_policy_for_requested_method(self):
        with self.introspection(self.claims) as call:
            result = auth.lambda_handler(self.event, None)
        self.assertEqual(result["principalId"], "user-1")
        self.assertEqual(result["policyDocument"]["Statement"][0], {
            "Action": "execute-api:Invoke", "Effect": "Allow", "Resource": self.event["methodArn"]})
        request = call.call_args.args[0]
        self.assertEqual(request.full_url, os.environ["OKTA_ISSUER"] + "/v1/introspect")
        self.assertIn(b"token=access-token", request.data)
        self.assertEqual(call.call_args.kwargs["timeout"], 5)

    def test_rejects_inactive_expired_wrong_issuer_and_wrong_audience(self):
        for updates in [{"active": False}, {"exp": 0}, {"exp": float("nan")}, {"aud": "other"},
                        {"iss": "https://other.okta.com"}, {"sub": ""}]:
            with self.subTest(updates=updates), self.introspection(self.claims | updates):
                with self.assertRaisesRegex(Exception, "^Unauthorized$"):
                    auth.lambda_handler(self.event, None)

    def test_missing_token_does_not_call_okta(self):
        with patch.object(auth, "urlopen") as call:
            with self.assertRaisesRegex(Exception, "^Unauthorized$"):
                auth.lambda_handler({}, None)
            call.assert_not_called()

    def test_network_failure_denies_access(self):
        with patch.object(auth, "urlopen", side_effect=URLError("unavailable")):
            with self.assertRaisesRegex(Exception, "^Unauthorized$"):
                auth.lambda_handler(self.event, None)


class BackendTests(unittest.TestCase):
    def setUp(self):
        environment = patch.dict(os.environ, {"PRODUCTS_TABLE": "products", "ORDERS_TABLE": "orders"})
        environment.start()
        self.addCleanup(environment.stop)
        resource = patch.object(backend.boto3, "resource")
        self.resource = resource.start()
        self.addCleanup(resource.stop)
        self.table = self.resource.return_value.Table.return_value

    def invoke(self, method="GET", path="/clops/products", **kwargs):
        result = backend.lambda_handler({"httpMethod": method, "path": path, **kwargs}, None)
        return result["statusCode"], json.loads(result["body"])

    def test_list_serializes_decimal_and_supports_pagination(self):
        self.table.scan.return_value = {"Items": [{"price": Decimal("12.50")}],
                                        "LastEvaluatedKey": {"productId": "p1"}}
        status, result = self.invoke(queryStringParameters={"limit": "10"})
        self.assertEqual(status, 200)
        self.assertEqual(result["items"], [{"price": 12.5}])
        self.invoke(queryStringParameters={"nextToken": result["nextToken"]})
        self.table.scan.assert_called_with(Limit=25, ExclusiveStartKey={"productId": "p1"})

    def test_read_item_and_missing_item(self):
        self.table.get_item.return_value = {"Item": {"orderId": "o1"}}
        self.assertEqual(self.invoke(path="/clops/orders/o1"), (200, {"orderId": "o1"}))
        self.resource.return_value.Table.assert_called_with("orders")
        self.table.get_item.assert_called_with(Key={"orderId": "o1"})
        self.table.get_item.return_value = {}
        self.assertEqual(self.invoke(path="/clops/orders/missing")[0], 404)

    def test_create_preserves_decimal_and_prevents_overwrite(self):
        body = base64.b64encode(b'{"productId":"p1","price":1.25}').decode()
        self.assertEqual(self.invoke("POST", body=body, isBase64Encoded=True)[0], 201)
        self.table.put_item.assert_called_once_with(
            Item={"productId": "p1", "price": Decimal("1.25")},
            ConditionExpression="attribute_not_exists(#pk)", ExpressionAttributeNames={"#pk": "productId"})

    def test_create_generates_id(self):
        status, result = self.invoke("POST", "/clops/orders", body='{"total":10}')
        self.assertEqual(status, 201)
        self.assertTrue(result["orderId"])

    def test_conflict(self):
        self.table.put_item.side_effect = ClientError(
            {"Error": {"Code": "ConditionalCheckFailedException"}}, "PutItem")
        self.assertEqual(self.invoke("POST", body='{"productId":"p1"}')[0], 409)

    def test_bad_input_never_writes(self):
        for body in ["not json", "[]", "{}", '{"productId":1}', '{"price":NaN}']:
            with self.subTest(body=body):
                self.assertEqual(self.invoke("POST", body=body)[0], 400)
        self.table.put_item.assert_not_called()
        self.assertEqual(self.invoke(queryStringParameters={"limit": "101"})[0], 400)
        self.assertEqual(self.invoke(queryStringParameters={"nextToken": "bad"})[0], 400)

    def test_unknown_route_and_unsupported_method(self):
        self.assertEqual(self.invoke(path="/clops/unknown")[0], 404)
        self.assertEqual(self.invoke("DELETE")[0], 405)
        self.assertEqual(self.invoke("POST", "/clops/products/p1", body='{}')[0], 405)

    def test_service_errors_are_raised(self):
        self.table.get_item.side_effect = ClientError(
            {"Error": {"Code": "InternalServerError"}}, "GetItem")
        with self.assertRaises(ClientError):
            self.invoke(path="/clops/products/p1")


class NotificationTests(unittest.TestCase):
    def test_processes_multiple_records(self):
        event = {"Records": [{"EventSource": "aws:sns", "Sns": {
            "MessageId": str(index), "TopicArn": "arn:aws:sns:us-east-1:123:updates",
            "Message": "notification\ntext"}} for index in range(2)]}
        with patch.object(sns.logger, "info") as log:
            self.assertEqual(sns.lambda_handler(event, None), {"processed": 2})
        self.assertEqual(log.call_count, 2)
        self.assertEqual(json.loads(log.call_args.args[0])["message"], "notification\ntext")

    def test_rejects_non_sns_events(self):
        for event in [{}, {"Records": []}, {"Records": [{"EventSource": "aws:s3"}]}]:
            with self.subTest(event=event), self.assertRaises(ValueError):
                sns.lambda_handler(event, None)


if __name__ == "__main__":
    unittest.main()
