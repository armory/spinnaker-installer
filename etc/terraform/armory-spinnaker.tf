variable "groundcontrol_images" {
  type = "map"

  default = {
    us-east-1 = "ami-14969103"
    us-west-1 = "ami-12a3f472"
    us-west-2 = "ami-bd359ddd"
  }
}

variable "armory_s3_bucket" { }
variable "armory_s3_path_prefix" { }
variable "armory_s3_config_path" { }

variable "instance_name" {
  default = "armory-spinnaker"
}

variable "armory_subnet_id" {
  default = ""
}

variable "aws_region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "m3.2xlarge"
}
variable "s3_front50_path_prefix" {
  default = "front50"
}

provider "aws" {
   region = "${var.aws_region}"
}

data "template_file" "spinnaker_user_data" {
  template = "${file("userdata.sh")}"

  vars {
    s3_path_prefix          = "${var.armory_s3_path_prefix}"
    s3_bucket               = "${var.armory_s3_bucket}"
    s3_config_path          = "${var.armory_s3_config_path}"
    s3_front50_path_prefix  = "${var.s3_front50_path_prefix}"
    instance_name           = "${var.instance_name}"
    aws_region              = "${var.aws_region}"
  }
}

resource "aws_security_group" "allow_all" {
  name = "spinnaker_allow_${var.instance_name}"
  description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 65535
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
    Name = "allow_all"
  }
}

resource "aws_instance" "spinnaker_instance" {
  ami                     = "${lookup(var.groundcontrol_images, var.aws_region)}"
  instance_type           = "${var.instance_type}"
  user_data               = "${data.template_file.spinnaker_user_data.rendered}"
  key_name                = "armory-spinnaker-keypair"
  vpc_security_group_ids  = ["${aws_security_group.allow_all.id}"]
  iam_instance_profile    = "BaseIAMRole"
  subnet_id               = "${var.armory_subnet_id}"
  tags {
    Name = "${var.instance_name}"
  }
}

output "spinnaker_instance_dns" {
    value = "${aws_instance.spinnaker_instance.public_dns}"
}
