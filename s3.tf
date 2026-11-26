resource "aws_s3_bucket" "main" {
  for_each = var.s3_buckets
  bucket   = each.value.s3_bucket_name

}

locals {
  static_content_types = {
    css  = "text/css; charset=utf-8"
    html = "text/html; charset=utf-8"
    js   = "application/javascript; charset=utf-8"
    json = "application/json"
    svg  = "image/svg+xml"
  }
}

resource "aws_s3_object" "static_site" {
  for_each = fileset("${path.module}/static-contents", "**")

  bucket = aws_s3_bucket.main["cloudfront"].id
  key    = each.value
  source = "${path.module}/static-contents/${each.value}"
  etag   = filemd5("${path.module}/static-contents/${each.value}")

  content_type = lookup(
    local.static_content_types,
    lower(element(reverse(split(".", each.value)), 0)),
    "application/octet-stream"
  )
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
