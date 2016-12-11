
resource "aws_elb" "armory_spinnaker_elb" {
  vpc_id = "${var.vpc_id}"
  name = "armory-spinnaker-elb"
  security_groups = [
    "${aws_security_group.armory_spinnaker_default.id}",
    "${aws_security_group.armory_spinnaker_web.id}"
  ]
  
  # The same availability zone as our instances
  availability_zones = ["${split(",", var.availability_zones)}"]

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
    instance_port     = 8084
    instance_protocol = "http"
    lb_port           = 8084
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
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:9000/"
    interval            = 30
  }
}

output "spinnaker_elb_dns" {
    value = "${aws_elb.armory_spinnaker_elb.public_dns}"
}