
variable "user_date" {}
variable "asg_name" {}
variable "elbs" {}


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

resource "aws_launch_configuration" "armory_spinnaker_rw_lc" {
  image_id              = "${data.aws_ami.armory_spinnaker_ami.id}"
  instance_type         = "${var.instance_type}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  iam_instance_profile  = "${aws_iam_role.SpinnakerInstanceProfile.name}"
  security_groups       = ["${aws_security_group.armory_spinnaker_default.id}"]
  user_data             = "${data.template_file.armory_spinnaker_ud.rendered}"
  key_name              = "${var.key_name}"

  lifecycle {
     create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "armory-spinnaker-asg" {
  availability_zones    = ["${split(",", var.availability_zones)}"]
  name                  = "${var.spinnaker_asg_name}"
  max_size              = "${var.asg_max}"
  min_size              = "${var.asg_min}"
  desired_capacity      = "${var.asg_desired}"
  force_delete          = true
  health_check_grace_period = 300
  health_check_type         = "ELB"
  launch_configuration  = "${aws_launch_configuration.armory_spinnaker_rw_lc.name}"
  load_balancers        = ["${aws_elb.armory_spinnaker_elb.name}"]
  vpc_zone_identifier   = ["${var.armory_subnet_id}"]

  tag {
    key                 = "Name"
    value               = "armory-spinnaker"
    propagate_at_launch = "true"
  }
}
