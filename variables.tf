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
  type = map(object({
    handler     = string
    runtime     = string
    timeout     = number
    memory_size = number
    description = string
    filename    = string
  }))
}

variable "preferred_azs" {
  type        = list(string)
  description = "List of preferred availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}


###-----------dynamodb tables-----------###
variable "dynamodb_tables" {
  type = map(object({
    name-suffix = string
    hash_key    = string
    range_key   = string
    attributes = list(object({
      name = string
      type = string
    }))
  }))
  description = "Map of DynamoDB tables with their name suffixes"
}


####-----------s3 buckets-----------###
variable "s3_buckets" {
  type = map(object({
    s3_bucket_name = string
  }))
  description = "Map of S3 buckets with their names"
}