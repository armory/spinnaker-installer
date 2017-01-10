resource "aws_security_group" "armoryspinnaker_default" {
  vpc_id = "${var.vpc_id}"
  name = "${var.armoryspinnaker_default_sg_name}"
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

  # Allow internal communication between Spinnaker's subservices.
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_group_id = "${aws_security_group.armoryspinnaker_default.id}"
    self = true
  }

  tags {
    Name = "armoryspinnaker-default"
  }
}
