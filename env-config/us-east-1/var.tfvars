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
}

###-----------dynamodb tables-----------###
dynamodb_tables = {
  "products" = {
    name-suffix = "ddb-products"
    hash_key    = "productId"
    range_key   = ""
    attributes = [
      { name = "productId", type = "S" }
    ]
  }

  "orders" = {
    name-suffix = "ddb-orders"
    hash_key    = "orderId"
    range_key   = ""
    attributes = [
      { name = "orderId", type = "S" }
    ]
  }
}

