variable "application_name" {
  type        = string
  default     = ""
  description = "The name of the application"
}

variable "lambda_functions" {
  type = map(object({
    handler     = string
    runtime     = string
    timeout     = number
    memory_size = number
    description = string
    environment = optional(map(string), {})
  }))
}

variable "preferred_azs" {
  type        = list(string)
  description = "List of preferred availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "domain_name" {
  type        = string
  description = "Existing domain name managed in Cloudflare and used for the ShopHub site"
  default     = "auto8mate.com"
}


###-----------dynamodb tables-----------###
variable "dynamodb_tables" {
  type = map(object({
    name-suffix = string
    hash_key    = string
    range_key   = optional(string)
    attributes = list(object({
      name = string
      type = string
    }))
  }))
}


####-----------s3 buckets-----------###
variable "s3_buckets" {
  type = map(object({
    s3_bucket_name = string
  }))
  description = "Map of S3 buckets with their names"
}
