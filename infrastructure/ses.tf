resource "aws_ses_email_identity" "provisioner" {
  email = "provisioner@yourdomain.com"
}

resource "aws_ses_domain_identity" "domain" {
  domain = "yourdomain.com"
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.domain.domain
}
