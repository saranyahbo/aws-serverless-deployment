resource "aws_s3_bucket" "main" {
  for_each = var.s3_buckets
  bucket   = "${var.application_name}-${each.value.s3_bucket_name}"

}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = aws_s3_bucket.main
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