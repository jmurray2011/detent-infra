# Hosted zone and ACM certificate.
#
# Creates a public hosted zone for the provided domain and a wildcard
# cert validated against it. After apply, delegate the zone by adding
# the NS records (output: name_servers) to your registrar or parent zone.
# The cert will not validate until delegation is in place.

variable "domain_name" {
  description = "Domain for this environment (e.g. detent.example.com)."
  type        = string
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = local.tags
}

resource "aws_acm_certificate" "wildcard" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# No aws_acm_certificate_validation resource — we don't block on it.
# The cert validates automatically once the zone is delegated.
# The ALB accepts an unvalidated cert ARN; HTTPS works after delegation.
