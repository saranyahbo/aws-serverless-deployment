resource "aws_acm_certificate" "my_domain" {
  domain_name               = local.my_domain
  subject_alternative_names = ["*.${local.my_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Add ACM's validation CNAME records in Cloudflare before validation can finish.
# Use DNS only, with CNAME flattening disabled for these records.
resource "aws_acm_certificate_validation" "my_domain" {
  certificate_arn = aws_acm_certificate.my_domain.arn
  validation_record_fqdns = distinct([
    for option in aws_acm_certificate.my_domain.domain_validation_options : option.resource_record_name
  ])
}
