terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  backend "s3" {
    bucket = "cjo-terraform"
    key    = "spitfireofthegame.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_s3_bucket" "spitfireofthegame" {
  bucket = "spitfireofthegame.com"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "spitfireofthegame" {
  origin {
    domain_name = data.aws_s3_bucket.spitfireofthegame.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E2WOYOLD1LQGFF"
    }
  }
  enabled             = true
  default_root_object = "index.html"

  aliases = ["spitfireofthegame.com", "www.spitfireofthegame.com"]
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
    }
  }
}

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

resource "aws_acm_certificate" "cert" {
  domain_name               = "spitfireofthegame.com"
  subject_alternative_names = ["www.spitfireofthegame.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
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

resource "aws_s3_bucket" "website" {
  bucket = "spitfireofthegame.com"
}
