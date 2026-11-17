application_name = "clops"

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

