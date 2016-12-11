
variable "armory_s3_bucket" {
    description = "S3 Bucket to persist Spinnaker's state."
}

variable "s3_front50_path_prefix" {
  description = "Within the previously specified S3 bucket, this is the prefix to use for persisting Spinnaker's state."
  default = "front50"
}

variable "armory_subnet_id" {
  description = "The subnet in which you want Spinnaker to live."
}

variable "aws_region" {
  description = "The region in which you want Spinnaker to live."
  #default = "us-west-2"
}

variable "availability_zones" {
  description = "The availability zone(s) in which you want Spinnaker to live."
}

variable "instance_type" {
  description = "The instance type in which you want Spinnaker to live."
  default = "m3.2xlarge"
}

variable "key_name" { }

variable "asg_max" {
    default = 1
}

variable "asg_min" {
    default = 1
}

variable "asg_desired" {
    default = 1
}