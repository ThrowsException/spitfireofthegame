resource "aws_acm_certificate" "cert" {
  domain_name               = "spitfireofthegame.com"
  subject_alternative_names = ["www.spitfireofthegame.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
