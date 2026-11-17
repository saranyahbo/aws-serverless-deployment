variable "application_name" {
  type        = string
  default     = ""
  description = "The name of the application"
}

variable "authorizer_lambda_arn" {
  type        = string
  default     = ""
  description = "The URI of the Okta authorizer Lambda function"
}

variable "lambda_functions" {
  type = map(objects({
    function_name = string
    handler       = string
    runtime       = string
    timeout       = number
    memory_size   = number
    description   = string
  }))
}

variable "preferred_azs" {
  type        = list(string)
  description = "List of preferred availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}
