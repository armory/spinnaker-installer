
resource "aws_security_group" "armory_spinnaker_elb" {
  vpc_id = "${var.vpc_id}"
  name = "${var.spinnaker_elb_sg_name}"
  description = "Allows web traffic to the dashboard."

  ingress {
      from_port = 9000
      to_port = 9000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8084
      to_port = 8084
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.spinnaker_elb_sg_name}"
  }
}

resource "aws_security_group" "armory_spinnaker_default" {
  vpc_id = "${var.vpc_id}"
  name = "${var.spinnaker_default_sg_name}"
  description = "Allows communication between Spinnaker services."

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    # security_group_id = "${aws_security_group.armory_spinnaker_default.id}"
    self = true
  }

  tags {
    Name = "armory-spinnaker-default"
  }
}