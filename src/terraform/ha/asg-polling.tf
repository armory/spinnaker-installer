
module "asg-polling" {
  source = "../modules/asg"
  asg_name = "armoryspinnaker-ha-polling"
  asg_size_min = 1
  asg_size_max = 1
  asg_size_desired = 1
  clouddriver_polling = "true"
  internal_dns_name = "${aws_elb.armoryspinnaker_internal_elb.dns_name}"
  external_dns_name = "${aws_elb.armoryspinnaker_external_elb.dns_name}" 
  load_balancers = [
    "${aws_elb.armory_spinnaker_external_elb.dns_name}", 
    "${aws_elb.armory_spinnaker_internal_elb.dns_name}"
  ]
}