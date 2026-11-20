output "acm_dns_validation_records" {
  description = "Create these CNAMEs in Cloudflare as DNS only, without CNAME flattening. Keep them for certificate renewal."
  value = toset([
    for option in aws_acm_certificate.my_domain.domain_validation_options : {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  ])
}

output "cloudfront_dns_records" {
  description = "Create these application CNAMEs in Cloudflare as DNS only after CloudFront deployment."
  value = [
    for name in sort(tolist(aws_cloudfront_distribution.s3_distribution.aliases)) : {
      name  = name
      type  = "CNAME"
      value = aws_cloudfront_distribution.s3_distribution.domain_name
    }
  ]
}

output "cloudfront_domain_name" {
  description = "AWS-provided hostname for the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
