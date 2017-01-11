/*
module "asg-nonpolling" {
  source = "../modules/asg"
  asg_name = "armoryspinnaker-ha"
  asg_size_min = 2
  asg_size_max = 2
  asg_size_desired = 2
  clouddriver_polling = "false"
  internal_dns_name = "${aws_elb.armoryspinnaker_internal.dns_name}"
  external_dns_name = "localhost" #"${aws_elb.armoryspinnaker_external.dns_name}" 
  load_balancers = [
    #"${aws_elb.armoryspinnaker_external.dns_name}", 
    "${aws_elb.armoryspinnaker_internal.dns_name}"
  ]
}
*/
