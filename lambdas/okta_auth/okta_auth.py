"""Validate access tokens with the configured Okta authorization server."""

import base64
import json
import logging
import math
import os
import time
from urllib.error import URLError
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen

logger = logging.getLogger(__name__)


def lambda_handler(event, context):
    authorization = event.get("authorizationToken", "").split()
    if len(authorization) != 2 or authorization[0].lower() != "bearer":
        raise Exception("Unauthorized")

    issuer = os.environ["OKTA_ISSUER"].rstrip("/")
    audience = os.environ["OKTA_AUDIENCE"]
    client_id = os.environ["OKTA_CLIENT_ID"]
    client_secret = os.environ["OKTA_CLIENT_SECRET"]
    if (urlparse(issuer).scheme != "https" or not urlparse(issuer).netloc
            or not all((audience, client_id, client_secret))):
        raise RuntimeError("Configure HTTPS OKTA_ISSUER and Okta client settings")

    credentials = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()
    request = Request(
        f"{issuer}/v1/introspect",
        data=urlencode({"token": authorization[1], "token_type_hint": "access_token"}).encode(),
        headers={"Authorization": f"Basic {credentials}",
                 "Content-Type": "application/x-www-form-urlencoded",
                 "Accept": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=5) as response:
            claims = json.load(response)
    except (URLError, TimeoutError, ValueError):
        logger.error("Okta introspection failed")
        raise Exception("Unauthorized") from None

    if (not isinstance(claims, dict) or claims.get("active") is not True
            or claims.get("iss") != issuer or claims.get("aud") != audience
            or not isinstance(claims.get("exp"), (int, float))
            or not math.isfinite(claims["exp"])
            or claims["exp"] <= time.time() or not claims.get("sub")):
        raise Exception("Unauthorized")

    return {
        "principalId": claims["sub"],
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [{"Action": "execute-api:Invoke", "Effect": "Allow",
                           "Resource": event["methodArn"]}],
        },
    }
