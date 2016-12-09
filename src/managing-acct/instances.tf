#
# TODO: Shouldnt have public IP
#
data "template_file" "armory_spinnaker_ud" {
  template = "${file("userdata.sh")}"
  vars {
    s3_bucket               = "${var.armory_s3_bucket}"
    s3_front50_path_prefix  = "${var.s3_front50_path_prefix}"
    aws_region              = "${var.aws_region}"
  }
}

resource "aws_launch_configuration" "armory_spinnaker_lc" {
  name                  = "armory-spinnaker-lc"
  image_id              = "ami-0a9d366a" //"${lookup(var.spinnaker_images, var.aws_region)}"
  instance_type         = "${var.instance_type}"
  iam_instance_profile  = "BaseIAMRole"
  security_groups       = ["${aws_security_group.armory_spinnaker_default.id}"]
  user_data             = "${data.template_file.armory_spinnaker_ud.rendered}"
  key_name              = "${var.key_name}"  
}

resource "aws_autoscaling_group" "armory-spinnaker-asg" {
  availability_zones    = ["${split(",", var.availability_zones)}"]
  name                  = "armory-spinnaker-asg"
  max_size              = "${var.asg_max}"
  min_size              = "${var.asg_min}"
  desired_capacity      = "${var.asg_desired}"
  force_delete          = true
  # health_check_grace_period = 300
  # health_check_type         = "ELB"
  launch_configuration  = "${aws_launch_configuration.armory_spinnaker_lc.name}"
  load_balancers        = ["${aws_elb.armory_spinnaker_elb.name}"]
  vpc_zone_identifier   = ["${var.armory_subnet_id}"]
  tag {
    key                 = "Name"
    value               = "armory-spinnaker"
    propagate_at_launch = "true"
  }
}
