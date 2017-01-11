
module "asg" {
  source = "../modules/asg"
  asg_name = "armoryspinnaker-standalone"
  asg_size_min = 1
  asg_size_max = 1
  asg_size_desired = 1
  clouddriver_polling = "true"
  internal_dns_name = "localhost"
  external_dns_name = "${aws_elb.armoryspinnaker_external_elb.dns_name}" 
  load_balancers = [
    "${aws_elb.armoryspinnaker_external_elb.dns_name}"
  ]
}