
#
# Location
#

variable "aws_region" {
  description = "The region in which you want Spinnaker to live."
}

variable "vpc_id" {
  description = "The VPC in which you want Spinnaker to live."
}

variable "armoryspinnaker_subnet_ids" {
  description = "The subnets in which you want Spinnaker to live."
}

variable "s3_bucket" {
  description = "S3 Bucket to persist Spinnaker's state."
}

variable "s3_prefix" {
  description = "Within the previously specified S3 bucket, this is the prefix to use for persisting Spinnaker's state."
  default = "armoryspinnaker"
}

#
# Roles / Policies
#

variable "armoryspinnaker_assume_policy_name" {
  description = "The name of the assume policy you want spinnaker to use"
  default = "SpinnakerAssumePolicy"
}

variable "armoryspinnaker_instance_profile_name" {
  description = "The name of the role you want to use for the Spinnaker instance"
  default = "SpinnakerInstanceProfile"
}

variable "armoryspinnaker_managed_profile_name" {
  description = "The name of the managed role you want Spinnaker to manage"
  default = "SpinnakerManagedProfile"
}

variable "armoryspinnaker_ecr_access_policy_name" {
  description = "The ECR access policy name.  The Spinnaker instances uses ECR to download containers necessary to run Spinnaker"
  default = "SpinnakerECRAccessPolicy"
}

variable "armoryspinnaker_access_policy_name" {
  description = "The name of the access policy you want spinnaker to have"
  default = "SpinnakerAccessPolicy"
}

variable "armoryspinnaker_s3_access_policy_name" {
  description = "By default Spinnaker uses S3 as it's backing store for pipelines & applications data and requires a policy"
  default = "SpinnakerS3AccessPolicy"
}

#
# Load Balancing
#

variable "armoryspinnaker_internal_elb_name" {
  description = "The name of the ELB that spinnaker subservices will use"
  default = "armoryspinnaker-ha-internal"
}

variable "armoryspinnaker_external_elb_name" {
  description = "The name of the ELB that users will use"
  default = "armoryspinnaker-ha-external"
}

#
# Cache
#

variable "use_existing_cache" {
  description = "Should a new cache be created or should an existing cache be used."
  default = "false"  
}

variable "existing_cache_endpoint" {
  description = "If existing cache should be used, what is its primary endpoint"
  default = "not_used"
}

variable "armoryspinnaker_cache_name" {
  description = "The name of the elasticache redis cluster to create"
  default = "armoryspinnaker"
}

variable "armoryspinnaker_cache_subnet_name" {
  description = "The name of the elasticache subnet security group"
  default = "armoryspinnaker-cache-subnet"
}

#
# Security
#

variable "armoryspinnaker_external_sg_name" {
  description = "The name of the security group to give to allow web traffic to the dashboard"
  default = "armoryspinnaker-external"
}

variable "armoryspinnaker_default_sg_name" {
  description = "The name of the default security group that allows Spinnaker sub-services to communicate"
  default = "armoryspinnaker-default"
}

variable "associate_public_ip_address" {
  description = "Wether or not the spinnaker instance itself has a public ip, defaults to false"
  default = "false"
}

variable "shared_credentials_file" {
  description = "The path of the shared credentials file to be used, default ~/.aws/credentials"
  default = "~/.aws/credentials"
}

variable "key_name" {
  description = "An already existing AWS key pair which will be used to secure the EC2 instances."
}

#
# Instances / Replication
#

variable "armoryspinnaker_asg" {
  default = "armoryspinnaker-ha-v000"
}

variable "armoryspinnaker_asg_polling" {
  default = "armoryspinnaker-ha-polling-v000"
}

variable "instance_type" {
  description = "The instance type in which you want Spinnaker to live."
  default = "m3.2xlarge"
}

variable "images" {
  type = "map"

  default = {
    us-west-2 = "ami-b18d30d1"
  }
}
