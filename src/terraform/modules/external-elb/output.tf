output "dns_name" {
  value = "${aws_elb.armoryspinnaker_external.dns_name}"
}