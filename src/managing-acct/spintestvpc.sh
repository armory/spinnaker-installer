#!/bin/bash

cd "$(dirname "$0")"

export TF_VAR_vpc_id=vpc-7762cd13
export TF_VAR_armory_s3_bucket=armory-spkr
export TF_VAR_s3_front50_path_prefix=dev-front50
export TF_VAR_armory_subnet_id=subnet-8f5d43d6
export TF_VAR_availability_zones=us-west-2a
export TF_VAR_aws_region=us-west-2
export TF_VAR_key_name=spinnaker-05032016

terraform apply