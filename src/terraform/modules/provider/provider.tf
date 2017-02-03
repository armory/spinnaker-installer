variable "aws_region" {}

provider "aws" {
  region = "${var.aws_region}"
  /*shared_credentials_file  = "${var.shared_credentials_file}"
  profile                  = "${var.aws_profile}"*/
}
