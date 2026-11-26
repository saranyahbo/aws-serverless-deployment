resource "aws_s3_bucket" "main" {
  for_each = var.s3_buckets
  bucket   = each.value.s3_bucket_name

}

locals {
  static_site_files = toset([
    for file in fileset("${path.module}/static-contents", "**") : file
    if !endswith(file, ".tftpl")
  ])

  static_content_types = {
    css  = "text/css; charset=utf-8"
    html = "text/html; charset=utf-8"
    js   = "application/javascript; charset=utf-8"
    json = "application/json"
    svg  = "image/svg+xml"
  }

  frontend_runtime_config = templatefile("${path.module}/static-contents/config.js.tftpl", {
    api_base_url       = "${aws_api_gateway_stage.main.invoke_url}/clops"
    okta_issuer        = var.okta_issuer
    okta_spa_client_id = var.okta_spa_client_id
  })
}

resource "aws_s3_object" "static_site" {
  for_each = local.static_site_files

  bucket = aws_s3_bucket.main["cloudfront"].id
  key    = each.value
  source = "${path.module}/static-contents/${each.value}"
  etag   = filemd5("${path.module}/static-contents/${each.value}")

  content_type = lookup(
    local.static_content_types,
    lower(element(reverse(split(".", each.value)), 0)),
    "application/octet-stream"
  )
  cache_control = "no-cache"
}

resource "aws_s3_object" "frontend_runtime_config" {
  bucket        = aws_s3_bucket.main["cloudfront"].id
  key           = "config.js"
  content       = local.frontend_runtime_config
  content_type  = "application/javascript; charset=utf-8"
  cache_control = "no-cache"
  etag          = md5(local.frontend_runtime_config)
}

resource "aws_s3_bucket_metric" "cloudfront_origin" {
  bucket = aws_s3_bucket.main["cloudfront"].id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = {
    for key, bucket in aws_s3_bucket.main : key => bucket
    if key != "cloudfront"
  }
  bucket   = each.value.id

  rule {
    id     = "transition-to-glacier-after-30-days"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}
