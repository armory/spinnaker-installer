
resource "aws_security_group" "armory_spinnaker_web" {
  name = "armory-spinnaker-web"
  description = "Allows web traffic to the dashboard."

  ingress {
      from_port = 9000
      to_port = 9000
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
    Name = "armory-spinnaker-web"
  }
}

resource "aws_security_group" "armory_spinnaker_default" {
  name = "armory-spinnaker-default"
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

  tags {
    Name = "armory-spinnaker-default"
  }
}

# Allow communication within the spinnaker infrastructure.
resource "aws_security_group_rule" "armory_spinnaker_default" {
    type = "ingress"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.armory_spinnaker_default.id}"
    security_group_id = "${aws_security_group.armory_spinnaker_default.id}"
}


