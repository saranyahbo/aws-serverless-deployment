resource "aws_acm_certificate" "my_domain" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "my_domain" {
  certificate_arn = aws_acm_certificate.my_domain.arn
  # DNS remains managed in Cloudflare. Add the records from the
  # acm_dns_validation_records output there before the apply reaches this step.
  validation_record_fqdns = [
    for option in aws_acm_certificate.my_domain.domain_validation_options : option.resource_record_name
  ]
}
