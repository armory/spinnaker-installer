
resource "aws_elb" "armory_spinnaker_elb" {
  name = "${var.armory_spinnaker_elb_name}"
  subnets = ["${var.armory_subnet_id}"]
  security_groups = [
    "${aws_security_group.armory_spinnaker_default.id}",
    "${aws_security_group.armory_spinnaker_external_elb.id}"
  ]

  listener {
    instance_port     = 9000
    instance_protocol = "http"
    lb_port           = 9000
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 9000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8084
    instance_protocol = "http"
    lb_port           = 8084
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

resource "aws_security_group" "armory_spinnaker_external_elb" {
  vpc_id = "${var.vpc_id}"
  name = "${var.spinnaker_external_elb_sg_name}"
  description = "Allows web traffic to the dashboard and gate."

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
