application_name = "clops"

###-----------lambda-----------###
lambda_functions = {
  okta_auth = {
    handler     = "okta_auth.lambda_handler"
    runtime     = "python3.13"
    timeout     = 30
    memory_size = 128
    description = "Lambda function for Okta authorizer"
  },
  backend_function = {
    handler     = "backend_function.lambda_handler"
    runtime     = "python3.13"
    timeout     = 300
    memory_size = 128
    description = "Lambda function for backend processing"
  }
  sns_notification_function = {
    handler     = "sns_notification_function.lambda_handler"
    runtime     = "python3.13"
    timeout     = 30
    memory_size = 128
    description = "Lambda function for SNS notifications"
  }
}

###-----------dynamodb tables-----------###
# dynamodb_tables = {
#   "products" = {
#     name-suffix = "ddb-products"
#     hash_key    = "productId"
#     attributes = [
#       { name = "productId", type = "S" }
#     ]
#   }

#   "orders" = {
#     name-suffix = "ddb-orders"
#     hash_key    = "orderId"
#     attributes = [
#       { name = "orderId", type = "S" }
#     ]
#   }
# }

###-----------s3 buckets-----------###
s3_buckets = {
  "frontend" = {
    s3_bucket_name = "clops-s3-frontend"
  }
  "assets" = {
    s3_bucket_name = "clops-s3-assets"
  }
  "access-logs" = {
    s3_bucket_name = "clops-s3-access-logs"
  }
  "cloudfront" = {
    s3_bucket_name = "clops-s3-cloudfront"
  }
}
