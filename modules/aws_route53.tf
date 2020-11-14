###################################
##### AWS Route53 DNS record ######
###################################


data "aws_route53_zone" "dns_zone" {
  name         = "${var.hosted_zone}."
  private_zone = var.hosted_zone_private
}

resource "aws_route53_record" "k8s_master_dns" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "${var.cluster_name}.${var.hosted_zone}"
  type    = "A"
  records = [aws_eip.k8s_master_eip.public_ip]
  ttl     = 300
}
