
data "template_file" "armoryspinnaker_ud" {
  template = <<EOF
#!/bin/bash
# wait for other services to come up
echo "Sleeping for 20 seconds before executing scripts..."
sleep 20

cat <<EOT > /etc/default/armory-spinnaker
#!/bin/bash
# Used to determine what services to start on the instance.
export ARMORY_SPINNAKER_MODE=ha
export LOCAL_REDIS=$${local_redis}
EOT

cat <<EOT > /opt/spinnaker/compose/environment
# Used by Spinnaker/front50 to persist pipelines:
ARMORY_S3_BUCKET=$${s3_bucket}
ARMORY_S3_FRONT50_PATH_PREFIX=$${s3_front50_path_prefix}
SPINNAKER_AWS_DEFAULT_REGION=$${aws_region}

# Gate URL used by Deck:
API_HOST=http://$${external_dns_name}:8084

# Used by the Spinnaker subservices to communicate internally:
DEFAULT_DNS_NAME=$${internal_dns_name}
AUTH_ENABLED=false
SPRING_CONFIG_LOCATION=/opt/spinnaker/config/
REDIS_HOST=$${redis_host}
CLOUDDRIVER_POLLING=$${clouddriver_polling}
EOT

service armory-spinnaker restart
EOF

  vars {
    s3_bucket               = "${var.armory_s3_bucket}"
    s3_front50_path_prefix  = "${var.s3_front50_path_prefix}"
    aws_region              = "${var.aws_region}"
    redis_host              = "${aws_elasticache_replication_group.armory-spinnaker-cache.primary_endpoint_address}"
    external_dns_name       = "${aws_elb.armory_spinnaker_external_elb.dns_name}"
    internal_dns_name       = "${aws_elb.armory_spinnaker_internal_elb.dns_name}"
    clouddriver_polling     = "${var.clouddriver_polling}"
    local_redis             = "${var.local_redis}"
  }
}


variable "release_tag" {
  default = "Release"
}

variable "release_tag_value" {
  default = "*"
}


data "aws_ami" "armory_spinnaker_ami" {
  filter {
    name = "state"
    values = ["available"]
  }
  filter {
    name = "name"
    values = ["armory-spinnaker*"]
  }
  most_recent = true
}

resource "aws_launch_configuration" "lc" {
  image_id              = "${data.aws_ami.armory_spinnaker_ami.id}"
  instance_type         = "${var.instance_type}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  iam_instance_profile  = "${aws_iam_role.SpinnakerInstanceProfile.name}"
  security_groups       = ["${aws_security_group.armory_spinnaker_default.id}"]
  user_data             = "${data.template_file.armoryspinnaker_ud.rendered}"
  user_data             = "${var.user_data}"
  key_name              = "${var.key_name}"

  lifecycle {
     create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "armory-spinnaker-asg" {
  name                      = "${var.asg_name}"
  max_size                  = "${var.asg_max}"
  min_size                  = "${var.asg_min}"
  desired_capacity          = "${var.asg_desired}"
  force_delete              = true
  health_check_grace_period = 300
  health_check_type         = "ELB"
  launch_configuration      = "${aws_launch_configuration.lc.name}"
  load_balancers            = "${var.load_balancers}"
  vpc_zone_identifier       = "${var.subnet_ids}"

  tag {
    key                 = "Name"
    value               = "armoryspinnaker"
    propagate_at_launch = "true"
  }
}
