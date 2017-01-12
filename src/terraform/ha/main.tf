
module "provider" {
    source = "../modules/provider"
    aws_region = "${var.aws_region}"
}

module "default-sg" {
    source = "../modules/sg"
    vpc_id = "${var.vpc_id}"
    sg_name = "${var.armoryspinnaker_default_sg_name}"
}

module "managing-roles" {
    source = "../modules/managing-roles"
    instance_profile_name = "${var.armoryspinnaker_instance_profile_name}"
    managed_profile_name = "${var.armoryspinnaker_managed_profile_name}"
    access_policy_name = "${var.armoryspinnaker_access_policy_name}"
    assume_policy_name = "${var.armoryspinnaker_assume_policy_name}"
    ecr_access_policy_name = "${var.armoryspinnaker_ecr_access_policy_name}"
    s3_access_policy_name = "${var.armoryspinnaker_s3_access_policy_name}"
    s3_bucket = "${var.s3_bucket}"
}

module "redis" {
    source = "../modules/redis"
    cache_subnet_name = "${var.armoryspinnaker_cache_subnet_name}"
    subnet_ids = "${var.armoryspinnaker_subnet_ids}"
    cache_name = "${var.armoryspinnaker_cache_name}"
    default_sg_id = "${module.default-sg.id}"
}

#
# Instances / Replication
#

module "asg-polling" {
  source = "../modules/asg"
  asg_name = "armoryspinnaker-ha-polling"
  asg_size_min = 1
  asg_size_max = 1
  asg_size_desired = 1
  clouddriver_polling = "true"
  internal_dns_name = "${aws_elb.armoryspinnaker_internal.dns_name}"
  external_dns_name = "${module.external-elb.dns_name}" 
  load_balancers = [
    "${module.external-elb.dns_name}", 
    "${aws_elb.armoryspinnaker_internal.dns_name}"
  ]
  local_redis = false
  redis_primary_endpoint_address = "${module.redis.primary_endpoint_address}"
  instance_type = "${var.instance_type}"
  associate_public_ip_address = false
  default_sg_id = "${module.default-sg.id}"
  
  key_name = "${var.key_name}"
  s3_bucket = "${var.s3_bucket}"
  s3_prefix = "${var.s3_prefix}"
  default_aws_region = "${var.aws_region}"
  instance_profile = "${var.armoryspinnaker_instance_profile_name}"
  subnet_ids = "${var.armoryspinnaker_subnet_ids}"
}

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

#
# Load Balancing
#

module "external-elb" {
    source = "../modules/external-elb"
    elb_name = "${var.armoryspinnaker_external_elb_name}"
    vpc_id = "${var.vpc_id}"
    subnet_ids = "${var.armoryspinnaker_subnet_ids}"
    default_sg_id = "${module.default-sg.id}"
    external_sg_name = "${var.armoryspinnaker_external_sg_name}"
}

resource "aws_elb" "armoryspinnaker_internal" {
  name = "${var.armoryspinnaker_internal_elb_name}"
  subnets = ["${var.armoryspinnaker_subnet_ids}"]
  internal = true
  security_groups = [
    "${module.default-sg.id}"
  ]

  listener {
    instance_port     = 9000
    instance_protocol = "http"
    lb_port           = 9000
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8084
    instance_protocol = "http"
    lb_port           = 8084
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 7002
    instance_protocol = "http"
    lb_port           = 7002
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8089
    instance_protocol = "http"
    lb_port           = 8089
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8088
    instance_protocol = "http"
    lb_port           = 8088
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8083
    instance_protocol = "http"
    lb_port           = 8083
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8087
    instance_protocol = "http"
    lb_port           = 8087
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    target              = "HTTP:5000/healthcheck"
    interval            = 5
  }
}

