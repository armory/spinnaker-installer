resource "aws_elb" "armoryspinnaker_internal" {
  name = "${var.armoryspinnaker_internal_elb_name}"
  subnets = "${var.armoryspinnaker_subnet_ids}"
  internal = true
  security_groups = [
    "${var.armoryspinnaker_default_security_group_id}"
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
