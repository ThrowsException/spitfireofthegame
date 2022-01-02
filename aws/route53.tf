resource "aws_route53_zone" "website" {
  name = "spitfireofthegame.com"
}

resource "aws_route53_record" "www" {
  allow_overwrite = true
  name            = "www.spitfireofthegame.com"
  type            = "A"
  zone_id         = aws_route53_zone.website.zone_id

  alias {
    name                   = aws_cloudfront_distribution.spitfireofthegame.domain_name
    zone_id                = aws_cloudfront_distribution.spitfireofthegame.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "default" {
  allow_overwrite = true
  name            = "spitfireofthegame.com"
  type            = "A"
  zone_id         = aws_route53_zone.website.zone_id

  alias {
    name                   = aws_cloudfront_distribution.spitfireofthegame.domain_name
    zone_id                = aws_cloudfront_distribution.spitfireofthegame.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cname" {

  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = aws_route53_zone.website.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}
