
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
    use_existing_cache = "${var.use_existing_cache}"
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
  ami_id = "${lookup(var.armoryspinnaker_ami, var.aws_region)}"
  asg_name = "${var.armoryspinnaker_asg_polling}"
  asg_size_min = 1
  asg_size_max = 1
  asg_size_desired = 1
  load_balancers = "${var.armoryspinnaker_external_elb_name},${var.armoryspinnaker_internal_elb_name}"
  instance_type = "${var.instance_type}"
  associate_public_ip_address = false
  default_sg_id = "${module.default-sg.id}"
  key_name = "${var.key_name}"
  instance_profile = "${var.armoryspinnaker_instance_profile_name}"
  subnet_ids = "${var.armoryspinnaker_subnet_ids}"
  
  # User-data info:
  mode = "ha"
  default_iam_role = "${var.armoryspinnaker_instance_profile_name}"
  default_assume_role = "${var.armoryspinnaker_managed_profile_name}"
  clouddriver_profiles = "armory,local"
  internal_dns_name = "${aws_elb.armoryspinnaker_internal.dns_name}"
  external_dns_name = "${module.external-elb.dns_name}" 
  local_redis = "false"
  redis_primary_endpoint_address = "${var.use_existing_cache ? var.existing_cache_endpoint : module.redis.primary_endpoint_address}"
  s3_bucket = "${var.s3_bucket}"
  s3_prefix = "${var.s3_prefix}"
  default_aws_region = "${var.aws_region}"
}

module "asg-nonpolling" {
  source = "../modules/asg"
  ami_id = "${lookup(var.armoryspinnaker_ami, var.aws_region)}"
  asg_name = "${var.armoryspinnaker_asg}"
  asg_size_min = 2
  asg_size_max = 2
  asg_size_desired = 2
  load_balancers = "${var.armoryspinnaker_external_elb_name},${var.armoryspinnaker_internal_elb_name}"
  instance_type = "${var.instance_type}"
  associate_public_ip_address = false
  default_sg_id = "${module.default-sg.id}"
  key_name = "${var.key_name}"
  instance_profile = "${var.armoryspinnaker_instance_profile_name}"
  subnet_ids = "${var.armoryspinnaker_subnet_ids}"
  
  # User-data info:
  mode = "ha"
  default_iam_role = "${var.armoryspinnaker_instance_profile_name}"
  default_assume_role = "${var.armoryspinnaker_managed_profile_name}"
  clouddriver_profiles = "armory,local,nonpolling"
  internal_dns_name = "${aws_elb.armoryspinnaker_internal.dns_name}"
  external_dns_name = "${module.external-elb.dns_name}" 
  local_redis = "false"
  redis_primary_endpoint_address = "${var.use_existing_cache ? var.existing_cache_endpoint : module.redis.primary_endpoint_address}"
  s3_bucket = "${var.s3_bucket}"
  s3_prefix = "${var.s3_prefix}"
  default_aws_region = "${var.aws_region}"
}

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
  subnets = ["${split(",", var.armoryspinnaker_subnet_ids)}"]
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

