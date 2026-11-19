resource "aws_acm_certificate" "my_domain" {
    domain_name     = "auto8mate.com"
    validation_method = "DNS"

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_route53_record" "my_domain_validation" {
    for_each = {
        for dvo in aws_acm_certificate.my_domain.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            type   = dvo.resource_record_type
            record = dvo.resource_record_value
        }
    }

    zone_id = data.aws_route53_zone.my_domain.zone_id
    name    = each.value.name
    type    = each.value.type
    records = [each.value.record]
    ttl     = 60
}

resource "aws_acm_certificate_validation" "my_domain" {
    certificate_arn         = aws_acm_certificate.my_domain.arn
    validation_record_fqdns = [for record in aws_route53_record.my_domain_validation : record.fqdn]
}