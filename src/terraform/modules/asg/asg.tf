
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
ARMORYSPINNAKER_S3_BUCKET=$${s3_bucket}
ARMORYSPINNAKER_S3_PREFIX=$${s3_prefix}
SPINNAKER_AWS_DEFAULT_REGION=$${default_aws_region}

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
    default_aws_region      = "${var.default_aws_region}"
    s3_bucket               = "${var.s3_bucket}"
    s3_prefix               = "${var.s3_prefix}"
    external_dns_name       = "${var.external_dns_name}"
    internal_dns_name       = "${var.internal_dns_name}"
    clouddriver_polling     = "${var.clouddriver_polling}"
    local_redis             = "${var.local_redis}"
    redis_host              = "${var.redis_primary_endpoint_address}"
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
  iam_instance_profile  = "${var.instance_profile}"
  security_groups       = ["${var.default_sg_id}"]
  user_data             = "${data.template_file.armoryspinnaker_ud.rendered}"
  key_name              = "${var.key_name}"

  lifecycle {
     create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "armory-spinnaker-asg" {
  name                      = "${var.asg_name}"
  max_size                  = "${var.asg_size_max}"
  min_size                  = "${var.asg_size_min}"
  desired_capacity          = "${var.asg_size_desired}"
  force_delete              = true
  health_check_grace_period = 300
  health_check_type         = "ELB"
  launch_configuration      = "${aws_launch_configuration.lc.name}"
  load_balancers            = ["${var.load_balancers}"]
  vpc_zone_identifier       = ["${split(",", var.subnet_ids}"]

  tag {
    key                 = "Name"
    value               = "armoryspinnaker"
    propagate_at_launch = "true"
  }
}
