# 1. Pull existing Route 53 Zone data
data "aws_route53_zone" "main" {
  name         = var.app_domain
  private_zone = false
}

# 2. Create the DNS "A" Record (Points your domain to the ALB)
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = data.aws_route53_zone.main.name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

# 3. Create the SSL Certificate (ACM)
resource "aws_acm_certificate" "cert" {
  domain_name       = data.aws_route53_zone.main.name
  validation_method = "DNS"

  tags = {
    Name = data.aws_route53_zone.main.name
  }
}

# 4. Create DNS Records to prove you own the domain (Validation)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# 5. The final "Handshake" to validate the SSL Certificate
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
